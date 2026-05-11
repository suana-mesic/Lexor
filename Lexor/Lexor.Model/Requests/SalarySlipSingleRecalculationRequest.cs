namespace Lexor.Model.Requests
{
    public class SalarySlipSingleRecalculationRequest
    {
        public int EmployeeId { get; set; }
        public int Year { get; set; }
        public int Month { get; set; }

    }
}
