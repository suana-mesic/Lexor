namespace Lexor.Model.Requests
{
    public class SalarySlipCalculationRequest
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public int? EmployeeId { get; set; }
    }
}
