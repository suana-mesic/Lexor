using Lexor.Model.Enums;

namespace Lexor.Model.Responses
{
    public class EmployeeResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public UserResponse User { get; set; } = null!;
        public DateTime DateOfBirth { get; set; }
        public string Address { get; set; } = string.Empty;
        public CityResponse City { get; set; } = null!;
        public DepartmentResponse Department { get; set; } = null!;
        public PositionResponse Position { get; set; } = null!;
        public DateTime HireDate { get; set; }
        public bool IsActive { get; set; } = true;
        public List<ContractResponse> Contracts { get; set; } = new();

        public class UserResponse
        {
            public int Id { get; set; }
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
            public string? Username { get; set; }
            public string Email { get; set; } = string.Empty;
            public string? PhoneNumber { get; set; }
            public string? ProfileImageBase64 { get; set; }

            // Small 96x96 avatar returned in list responses (the full image above is
            // stripped there) so tables can show the photo without a heavy payload.
            public string? ProfileThumbnailBase64 { get; set; }
            public bool IsCodeActivated { get; set; }
        }

        public class ContractResponse
        {
            public int Id { get; set; }
            public int ContractTypeId { get; set; }
            public string ContractTypeName { get; set; } = string.Empty;
            public DateTime StartDate { get; set; }
            public DateTime? EndDate { get; set; }
            public decimal BrutoSalary { get; set; }
            public int WorkHoursPerDay { get; set; } = 8;

            // Derived from the date range vs today — not stored (see guidelines A.4 for UtcNow).
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
        }

        public class CityResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
            public CountryResponse Country { get; set; } = null!;
        }

        public class CountryResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
        }

        public class DepartmentResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
        }

        public class PositionResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
        }
    }
}
