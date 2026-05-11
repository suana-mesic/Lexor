namespace Lexor.Model.Requests
{
    public class SalarySlipCalculationUpdateRequest
    {
        public int EmployeeId { get; set; }
        public int Year { get; set; }
        public int Month { get; set; }
    }
}
