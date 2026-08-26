using Lexor.Model.Enums;

namespace Lexor.Model.Responses
{
    public class SalarySlipResponse
    {
        public int Id { get; set; }
        public EmployeeResponse Employee { get; set; } = null!;
        public int Year { get; set; }
        public int Month { get; set; }
        public decimal BrutoSalary { get; set; }
        public decimal AdjustedBruto { get; set; }
        public decimal TotalContributions { get; set; }
        public decimal TaxBase { get; set; }
        public decimal Tax { get; set; }
        public decimal NetSalary { get; set; }
        public SalarySlipStatus Status { get; set; } = SalarySlipStatus.Pending;
        public DateTime GeneratedAt { get; set; }
        public DateTime? PaidAt { get; set; }
        public List<ItemResponse>? Items { get; set; } 

        public class ItemResponse
        {
            public int Id { get; set; }

            public SalarySlipItemType ItemType { get; set; }

            public string Name { get; set; } = string.Empty;

            public string? Description { get; set; }

            public decimal? Quantity { get; set; }

            public decimal? Rate { get; set; }

            public decimal? Multiplier { get; set; }

            public decimal Amount { get; set; }
        }

        public class EmployeeResponse
        {
            public int Id { get; set; }
            public UserResponse User { get; set; } = null!;
            // Filled only where Department is loaded (monthly report); null in list views.
            public string? DepartmentName { get; set; }
        }

        public class UserResponse
        {
            public int Id { get; set; }
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;

            // Small avatar so list views can show the person's photo next to their name
            // (guideline 6) without carrying the full-size image (guideline 8.2).
            public string? ProfileThumbnailBase64 { get; set; }
        }
    }
}
