namespace Lexor.Model.Responses
{
    public class DashboardResponse
    {
        public int TotalEmployees { get; set; }
        public int NewEmployeesThisMonth { get; set; }
        public int ActiveContracts { get; set; }
        public int ExpiringContractsSoon { get; set; }
        public double AttendanceRate { get; set; }
        public double AttendanceRateChange { get; set; }
        public int PendingLeaves { get; set; }
        public int PendingVacationLeaves { get; set; }
        public List<LeavesByDayItem> LeavesByDay { get; set; } = [];
        public List<LeavesByTypeItem> LeavesByType { get; set; } = [];
        public List<LeavesByStatusItem> LeavesByStatus { get; set; } = [];
        public HrMetricsItem HrMetrics { get; set; } = new();
    }
    public class LeavesByDayItem
    {
        public DateTime Date { get; set; }
        public string DayLabel { get; set; } = string.Empty;
        public int Count { get; set; }
    }
    public class LeavesByTypeItem
    {
        public string TypeName { get; set; } = string.Empty;
        public int Count { get; set; }
    }
    public class LeavesByStatusItem
    {
        public string Status { get; set; } = string.Empty;
        public int Count { get; set; }
    }

    public class HrMetricsItem
    {
        public double AttendanceRate { get; set; }
        public double ContractFillRate { get; set; }
        public double LeaveApprovalRate { get; set; }
        public double SalaryPaymentRate { get; set; }
        public double ActiveEmployeeRate { get; set; }
    }
}
