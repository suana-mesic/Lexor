using Lexor.Services.Database;
using Microsoft.EntityFrameworkCore;
using Lexor.Services.StateMachine.LeaveStateMachine;


namespace Lexor.Services.ML
{
    /// <summary>
    /// Current per-employee feature values (as of the end of recorded history),
    /// used to build samples for future days when forecasting.
    /// </summary>
    public class EmployeeAbsenceState
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public int DepartmentId { get; set; }
        public string DepartmentName { get; set; } = string.Empty;
        public float HistoricalAbsenceRate { get; set; }
        public float RecentAbsenceRate { get; set; }

        // Personal absence rate per calendar month (index 1-12), the seasonality feature.
        public float[] MonthRates { get; set; } = new float[13];

        public bool AbsentOnLastWorkday { get; set; }

        // Outcomes of the last five working days (0/1, oldest first).
        public List<float> LastFiveOutcomes { get; set; } = new();

        public List<(DateOnly From, DateOnly To)> PlannedLeaves { get; set; } = new();
    }

    /// <summary>
    /// Builds employee-day training samples from attendance history. A working day with no
    /// attendance stamp counts as an absence, regardless of the reason. Both rate features are
    /// computed strictly from days BEFORE the sample day, so the model never sees the answer
    /// it is being asked to predict (no data leakage).
    /// </summary>
    public static class AbsenceSampleBuilder
    {
        // First days per employee are skipped until the rate features stabilize.
        private const int WarmUpDays = 30;

        // Length of the rolling window behind RecentAbsenceRate.
        private const int RecentWindowDays = 30;

        public static async Task<List<AbsenceSample>> BuildAsync(LexorDbContext db)
        {
            var employees = await db.Employees
                .Where(e => e.IsActive)
                .Select(e => new { e.Id, e.DepartmentId, e.HireDate })
                .ToListAsync();

            var attendanceDays = (await db.Attendances
                    .Select(a => new { a.EmployeeId, a.Date })
                    .ToListAsync())
                .GroupBy(a => a.EmployeeId)
                .ToDictionary(g => g.Key, g => g.Select(a => a.Date).ToHashSet());

            // Planned leaves only (annual/paid/unpaid). Sick leave (LeaveTypeId 2) is excluded:
            // it is not known in advance, so it must not feed the OnPlannedLeave feature.
            var plannedLeaveRanges = (await db.Leaves
                    .Where(l => (l.State == nameof(ApprovedLeaveState)
                              || l.State == nameof(CompletedLeaveState))
                             && l.LeaveTypeId != 2)
                    .Select(l => new { l.EmployeeId, l.DateFrom, l.DateTo })
                    .ToListAsync())
                .GroupBy(l => l.EmployeeId)
                .ToDictionary(g => g.Key, g => g.Select(l => (l.DateFrom, l.DateTo)).ToList());

            if (attendanceDays.Count == 0)
                return new List<AbsenceSample>();

            // The observed history window is defined by the attendance data itself.
            var historyStart = attendanceDays.Values.SelectMany(d => d).Min();
            var historyEnd = attendanceDays.Values.SelectMany(d => d).Max();

            var samples = new List<AbsenceSample>();

            foreach (var employee in employees)
            {
                var days = attendanceDays.TryGetValue(employee.Id, out var set)
                    ? set
                    : new HashSet<DateOnly>();

                var myPlannedLeaves = plannedLeaveRanges.TryGetValue(employee.Id, out var lr)
                    ? lr
                    : new List<(DateOnly DateFrom, DateOnly DateTo)>();

                // An employee hired mid-window has no history before the hire date.
                var hireDate = DateOnly.FromDateTime(employee.HireDate);
                var start = hireDate > historyStart ? hireDate : historyStart;

                var pastTotal = 0;
                var pastAbsent = 0;
                var recent = new Queue<(DateOnly Day, bool Absent)>();
                var recentAbsent = 0;
                var prevWorkdayAbsent = false;
                var monthTotal = new int[13];
                var monthAbsent = new int[13];
                var lastFive = new Queue<bool>();
                var lastFiveAbsent = 0;

                for (var day = start; day <= historyEnd; day = day.AddDays(1))
                {
                    if (day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
                        continue;

                    var isAbsent = !days.Contains(day);

                    var onPlannedLeave = myPlannedLeaves.Any(r => day >= r.DateFrom && day <= r.DateTo);

                    // Slide the 30-day window: drop entries that fell out of it.
                    while (recent.Count > 0 && recent.Peek().Day < day.AddDays(-RecentWindowDays))
                    {
                        if (recent.Dequeue().Absent)
                            recentAbsent--;
                    }

                    // Emit a sample only after the warm-up, when both rates mean something.
                    if (day >= start.AddDays(WarmUpDays) && pastTotal > 0 && recent.Count > 0)
                    {
                        samples.Add(new AbsenceSample
                        {
                            DayOfWeek = day.DayOfWeek.ToString(),
                            Month = day.Month.ToString(),
                            Department = employee.DepartmentId.ToString(),
                            HistoricalAbsenceRate = (float)pastAbsent / pastTotal,
                            RecentAbsenceRate = (float)recentAbsent / recent.Count,
                            IsAbsent = isAbsent,
                            OnPlannedLeave = onPlannedLeave ? 1f : 0f,
                            PrevWorkdayAbsent = prevWorkdayAbsent ? 1f : 0f,
                            MonthSeasonRate = monthTotal[day.Month] > 0
                                ? (float)monthAbsent[day.Month] / monthTotal[day.Month]
                                : (float)pastAbsent / pastTotal,
                            AbsencesInLast5Workdays = lastFiveAbsent,
                        });
                    }

                    // Update the counters AFTER emitting the sample: the outcome of a day
                    // must never leak into that same day's features.
                    pastTotal++;
                    if (isAbsent) pastAbsent++;

                    recent.Enqueue((day, isAbsent));
                    if (isAbsent) recentAbsent++;

                    prevWorkdayAbsent = isAbsent;

                    monthTotal[day.Month]++;
                    if (isAbsent) monthAbsent[day.Month]++;

                    lastFive.Enqueue(isAbsent);
                    if (isAbsent) lastFiveAbsent++;
                    if (lastFive.Count > 5 && lastFive.Dequeue())
                        lastFiveAbsent--;
                }
            }

            return samples;
        }

        /// <summary>
        /// Computes each active employee's current feature values together with their
        /// planned leaves, for forecasting future days.
        /// </summary>
        public static async Task<List<EmployeeAbsenceState>> BuildCurrentStatesAsync(LexorDbContext db)
        {
            var employees = await db.Employees
                .Where(e => e.IsActive)
                .Select(e => new
                {
                    e.Id,
                    e.DepartmentId,
                    DepartmentName = e.Department.Name,
                    e.User.FirstName,
                    e.User.LastName,
                    e.HireDate
                })
                .ToListAsync();

            var attendanceDays = (await db.Attendances
                    .Select(a => new { a.EmployeeId, a.Date })
                    .ToListAsync())
                .GroupBy(a => a.EmployeeId)
                .ToDictionary(g => g.Key, g => g.Select(a => a.Date).ToHashSet());

            var plannedLeaveRanges = (await db.Leaves
                    .Where(l => (l.State == nameof(ApprovedLeaveState)
                              || l.State == nameof(CompletedLeaveState))
                             && l.LeaveTypeId != 2)
                    .Select(l => new { l.EmployeeId, l.DateFrom, l.DateTo })
                    .ToListAsync())
                .GroupBy(l => l.EmployeeId)
                .ToDictionary(g => g.Key, g => g.Select(l => (l.DateFrom, l.DateTo)).ToList());

            var result = new List<EmployeeAbsenceState>();
            if (attendanceDays.Count == 0)
                return result;

            var historyStart = attendanceDays.Values.SelectMany(d => d).Min();
            var historyEnd = attendanceDays.Values.SelectMany(d => d).Max();

            foreach (var employee in employees)
            {
                var days = attendanceDays.TryGetValue(employee.Id, out var set)
                    ? set
                    : new HashSet<DateOnly>();

                var hireDate = DateOnly.FromDateTime(employee.HireDate);
                var start = hireDate > historyStart ? hireDate : historyStart;

                var total = 0;
                var absent = 0;
                var recentTotal = 0;
                var recentAbsent = 0;
                var monthTotal = new int[13];
                var monthAbsent = new int[13];
                var lastFive = new Queue<bool>();
                var lastWorkdayAbsent = false;

                for (var day = start; day <= historyEnd; day = day.AddDays(1))
                {
                    if (day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
                        continue;

                    var isAbsent = !days.Contains(day);

                    total++;
                    if (isAbsent) absent++;

                    // The window end is fixed here (today), so a simple date check replaces
                    // the sliding queue used during training-sample generation.
                    if (day > historyEnd.AddDays(-RecentWindowDays))
                    {
                        recentTotal++;
                        if (isAbsent) recentAbsent++;
                    }

                    monthTotal[day.Month]++;
                    if (isAbsent) monthAbsent[day.Month]++;

                    lastFive.Enqueue(isAbsent);
                    if (lastFive.Count > 5)
                        lastFive.Dequeue();

                    lastWorkdayAbsent = isAbsent;
                }

                if (total == 0)
                    continue; // no working history yet -> nothing to base a prediction on

                var state = new EmployeeAbsenceState
                {
                    EmployeeId = employee.Id,
                    FullName = $"{employee.FirstName} {employee.LastName}",
                    DepartmentId = employee.DepartmentId,
                    DepartmentName = employee.DepartmentName,
                    HistoricalAbsenceRate = (float)absent / total,
                    RecentAbsenceRate = recentTotal > 0 ? (float)recentAbsent / recentTotal : 0f,
                    AbsentOnLastWorkday = lastWorkdayAbsent,
                    LastFiveOutcomes = lastFive.Select(b => b ? 1f : 0f).ToList(),
                    PlannedLeaves = plannedLeaveRanges.TryGetValue(employee.Id, out var lr)
                        ? lr
                        : new List<(DateOnly, DateOnly)>()
                };

                for (var m = 1; m <= 12; m++)
                    state.MonthRates[m] = monthTotal[m] > 0
                        ? (float)monthAbsent[m] / monthTotal[m]
                        : (float)absent / total;

                result.Add(state);
            }

            return result;
        }
    }
}