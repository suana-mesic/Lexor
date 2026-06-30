namespace Lexor.Model.Requests
{
    public class ContractInsertRequest
    {
        public int EmployeeId { get; set; }
        public int ContractTypeId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal BrutoSalary { get; set; }
        public int WorkHoursPerDay { get; set; } = 8;
    }
}
