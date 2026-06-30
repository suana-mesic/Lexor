using Lexor.Model.Responses;
using Lexor.Services.Database;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Lexor.Services.StateMachine.SalarySlipStateMachine;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly LexorDbContext _dbContext;
        public DashboardService(LexorDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public  async Task<DashboardResponse> GetDashboardDataAsync()
        {
            var now = DateTime.UtcNow;
            var firstDayOfMonth = new DateTime(now.Year, now.Month, 1);
            var in30Days = now.AddDays(30);
            var last7Days = Enumerable.Range(0, 7).Select(i => now.AddDays(-6 + i).Date).ToList();
            var weekStart = now.AddDays(-7).Date;
            var prevWeekStart = now.AddDays(-14).Date;
            var firstDayOfMonthDate = DateOnly.FromDateTime(firstDayOfMonth);
            var nowDate = DateOnly.FromDateTime(now);
            var weekStartDate = DateOnly.FromDateTime(weekStart);
            var prevWeekStartDate = DateOnly.FromDateTime(prevWeekStart);

            var totalEmployees = await _dbContext.Employees.CountAsync(e => e.IsActive);
            var allEmployeesCount = await _dbContext.Employees.CountAsync();
            var newEmployeesThisMonth = await _dbContext.Employees.CountAsync(e => e.HireDate >= firstDayOfMonth);
            var today = now.Date;
            // In effect today (date-derived, no stored flag).
            var activeContracts = await _dbContext.Contracts.CountAsync(
                c => c.StartDate.Date <= today && (c.EndDate == null || c.EndDate.Value.Date >= today));
            // Active and ending within the next 30 days.
            var expiringContractsSoon = await _dbContext.Contracts.CountAsync(
                c => c.EndDate != null && c.EndDate.Value.Date >= today && c.EndDate <= in30Days);
            var pendingLeaves = await _dbContext.Leaves.CountAsync(l => l.State == nameof(PendingLeaveState));
            var pendingVacationLeaves = await _dbContext.Leaves
                .Include(l => l.LeaveType)
                .CountAsync(l => l.State == nameof(PendingLeaveState) && l.LeaveType.IsPaid);

            // Attendance rate
            var workingDaysThisMonth = GetWorkingDays(firstDayOfMonth, now);
            var expectedAttendance = totalEmployees * workingDaysThisMonth;
            var actualAttendance = await _dbContext.Attendances.CountAsync(
                a => a.Date >= firstDayOfMonthDate && a.Date <= nowDate);
            var attendanceRate = expectedAttendance > 0
                ? (double)actualAttendance / expectedAttendance * 100 : 0;

            var thisWeekAttendance = await _dbContext.Attendances.CountAsync(
                a => a.Date >= weekStartDate && a.Date <= nowDate);
            var prevWeekAttendance = await _dbContext.Attendances.CountAsync(
                a => a.Date >= prevWeekStartDate && a.Date < weekStartDate);
            var thisWeekDays = GetWorkingDays(weekStart, now);
            var prevWeekDays = GetWorkingDays(prevWeekStart, weekStart.AddDays(-1));
            var expected = totalEmployees > 0 ? totalEmployees : 1;
            var thisWeekRate = thisWeekDays > 0 ? (double)thisWeekAttendance / (thisWeekDays * expected) * 100 : 0;
            var prevWeekRate = prevWeekDays > 0 ? (double)prevWeekAttendance / (prevWeekDays * expected) * 100 : 0;

            // Line chart
            var leaveDates = await _dbContext.Leaves
                .Where(l => l.CreatedAt.Date >= last7Days.First() && l.CreatedAt.Date <= last7Days.Last())
                .Select(l => l.CreatedAt.Date)
                .ToListAsync();

            var leavesByDay = last7Days.Select(date => new LeavesByDayItem
            {
                Date = date,
                DayLabel = date.ToString("ddd d. MMM"),
                Count = leaveDates.Count(d => d == date),
            }).ToList();

            // Bar chart
            var leavesByType = await _dbContext.Leaves
                .Include(l => l.LeaveType)
                .GroupBy(l => l.LeaveType.Name)
                .Select(g => new LeavesByTypeItem { TypeName = g.Key, Count = g.Count() })
                .ToListAsync();

            // Donut chart
            var leavesByStatus = await _dbContext.Leaves
                .GroupBy(l => l.State)
                .Select(g => new LeavesByStatusItem { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            // Radar chart
            var totalLeaves = await _dbContext.Leaves.CountAsync();
            var approvedLeaves = await _dbContext.Leaves.CountAsync(l => l.State == nameof(ApprovedLeaveState));
            var totalSlips = await _dbContext.SalarySlips.CountAsync();
            var paidSlips = await _dbContext.SalarySlips.CountAsync(s => s.State == nameof(PaidSalarySlipState));

            var hrMetrics = new HrMetricsItem
            {
                AttendanceRate = Math.Round(attendanceRate, 1),
                ContractFillRate = allEmployeesCount > 0
                    ? Math.Round((double)activeContracts / allEmployeesCount * 100, 1) : 0,
                LeaveApprovalRate = totalLeaves > 0
                    ? Math.Round((double)approvedLeaves / totalLeaves * 100, 1) : 0,
                SalaryPaymentRate = totalSlips > 0
                    ? Math.Round((double)paidSlips / totalSlips * 100, 1) : 0,
                ActiveEmployeeRate = allEmployeesCount > 0
                    ? Math.Round((double)totalEmployees / allEmployeesCount * 100, 1) : 0,
            };

            return new DashboardResponse
            {
                TotalEmployees = totalEmployees,
                NewEmployeesThisMonth = newEmployeesThisMonth,
                ActiveContracts = activeContracts,
                ExpiringContractsSoon = expiringContractsSoon,
                AttendanceRate = Math.Round(attendanceRate, 1),
                AttendanceRateChange = Math.Round(thisWeekRate - prevWeekRate, 1),
                PendingLeaves = pendingLeaves,
                PendingVacationLeaves = pendingVacationLeaves,
                LeavesByDay = leavesByDay,
                LeavesByType = leavesByType,
                LeavesByStatus = leavesByStatus,
                HrMetrics = hrMetrics,
            };
        }
        private static int GetWorkingDays(DateTime from, DateTime to)
        {
            int count = 0;
            for (var d = from.Date; d <= to.Date; d = d.AddDays(1))
                if (d.DayOfWeek != DayOfWeek.Saturday && d.DayOfWeek != DayOfWeek.Sunday)
                    count++;
            return count;
        }
    }
}
