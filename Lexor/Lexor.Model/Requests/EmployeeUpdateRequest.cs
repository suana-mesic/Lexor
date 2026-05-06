namespace Lexor.Model.Requests
{
    public class EmployeeUpdateRequest
    {
        public EmployeeUserUpdateRequest? User { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public int? CityId { get; set; }
        public int? DepartmentId { get; set; }
        public int? PositionId { get; set; }
        public DateTime? HireDate { get; set; }
        public bool? IsActive { get; set; }
    }

    public class EmployeeUserUpdateRequest
    {

        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
    }
}
