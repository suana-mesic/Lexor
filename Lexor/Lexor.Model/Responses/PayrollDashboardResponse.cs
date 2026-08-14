namespace Lexor.Model.Responses
{
    /// <summary>
    /// Finance/payroll overview for the accounting dashboard, computed for the most recent PAID month.
    /// </summary>
    public class PayrollDashboardResponse
    {
        public bool HasData { get; set; }
        public int Year { get; set; }
        public int Month { get; set; }

        public decimal TotalGross { get; set; }          // sum of adjusted bruto (net + contributions + tax)
        public decimal TotalNet { get; set; }
        public decimal TotalContributions { get; set; }
        public decimal TotalTax { get; set; }
        public decimal TotalOvertime { get; set; }       // overtime pay, KM
        public decimal TotalOvertimeHours { get; set; }  // overtime worked, hours
        public int EmployeesWithOvertime { get; set; }   // how many employees had any overtime
        public decimal BurdenRate { get; set; }          // (contributions + tax) / gross, %
        public decimal AverageNet { get; set; }
        public int SlipCount { get; set; }

        public List<OvertimeLeaderItem> TopOvertime { get; set; } = new();

        public class OvertimeLeaderItem
        {
            public string FullName { get; set; } = string.Empty;
            public decimal Hours { get; set; }
            public decimal Amount { get; set; }
        }
    }
}
