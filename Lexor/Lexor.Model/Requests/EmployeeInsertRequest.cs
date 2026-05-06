namespace Lexor.Model.Requests
{
    public class EmployeeInsertRequest
    {
        public EmployeeUserInsertRequest User { get; set; } = null!;
        public DateTime DateOfBirth { get; set; }
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public int DepartmentId { get; set; }
        public int PositionId { get; set; }
        public DateTime HireDate { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class EmployeeUserInsertRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
    }
}
