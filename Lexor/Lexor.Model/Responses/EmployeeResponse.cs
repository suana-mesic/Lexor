namespace Lexor.Model.Responses
{
    public class EmployeeResponse
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public EmployeeUserResponse User { get; set; } = null!;
        public DateTime DateOfBirth { get; set; }
        public string Address { get; set; } = string.Empty;
        public EmployeeCityResponse City { get; set; } = null!;
        public EmployeeDepartmentResponse Department { get; set; } = null!;
        public EmployeePositionResponse Position { get; set; } = null!;
        public DateTime HireDate { get; set; }
        public bool IsActive { get; set; } = true;
        public List<EmployeeContractResponse> Contracts { get; set; } = new();
    }

    public class EmployeeUserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? Username { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
        public bool IsCodeActivated { get; set; }
    }

    public class EmployeeContractResponse
    {
        public int Id { get; set; }
        public int ContractTypeId { get; set; }
        public string ContractTypeName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public decimal BrutoSalary { get; set; }
        public int WorkHoursPerDay { get; set; } = 8;
        public bool IsActive { get; set; } = true;
    }

    public class EmployeeCityResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public EmployeeCountryResponse Country { get; set; } = null!;
    }

    public class EmployeeCountryResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class EmployeeDepartmentResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }

    public class EmployeePositionResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
