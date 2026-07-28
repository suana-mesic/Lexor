using Lexor.Services.Database;
using Microsoft.EntityFrameworkCore;
using Lexor.Services.StateMachine.LeaveStateMachine;

namespace Lexor.Services.ML
{
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

            var leaveRanges = (await db.Leaves
                    .Where(l => l.State == nameof(ApprovedLeaveState)
                             || l.State == nameof(CompletedLeaveState))
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

                var myLeaves = leaveRanges.TryGetValue(employee.Id, out var lr)
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

                for (var day = start; day <= historyEnd; day = day.AddDays(1))
                {
                    if (day.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
                        continue;

                    var isAbsent = !days.Contains(day);

                    var onLeave = myLeaves.Any(r => day >= r.DateFrom && day <= r.DateTo);

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
                            OnApprovedLeave = onLeave ? 1f : 0f,
                            PrevWorkdayAbsent = prevWorkdayAbsent ? 1f : 0f,
                        });
                    }

                    // Update the counters AFTER emitting the sample: the outcome of a day
                    // must never leak into that same day's features.
                    pastTotal++;
                    if (isAbsent) pastAbsent++;

                    recent.Enqueue((day, isAbsent));
                    if (isAbsent) recentAbsent++;

                    prevWorkdayAbsent = isAbsent;
                }
            }

            return samples;
        }
    }
}