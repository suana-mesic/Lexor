namespace Lexor.Model.Responses
{
    public class ContractResponse
    {
        public int Id { get; set; }
        public int EmployeeId { get; set; }
        public int ContractTypeId { get; set; }
        public string ContractTypeName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal BrutoSalary { get; set; }
        public int WorkHoursPerDay { get; set; } = 8;
        public bool IsActive { get; set; } = true;
    }
}
