using Lexor.Model.Enums;

namespace Lexor.Model.Responses
{
    public class ContractResponse
    {
        public int Id { get; set; }
        public int EmployeeId { get; set; }
        public int ContractTypeId { get; set; }
        public ContractTypeResponse ContractType { get; set; } = null!;
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal BrutoSalary { get; set; }
        public int WorkHoursPerDay { get; set; } = 8;

        // Derived from the date range vs today — not stored. UtcNow keeps it consistent across the app (see guidelines A.4).
        public ContractStatus Status
        {
            get
            {
                var today = DateTime.UtcNow.Date;
                if (StartDate.Date > today)
                    return ContractStatus.Upcoming;
                if (EndDate.HasValue && EndDate.Value.Date < today)
                    return ContractStatus.Expired;
                return ContractStatus.Active;
            }
        }

        public class ContractTypeResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
        }
    }
}
