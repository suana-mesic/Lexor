namespace Lexor.Model.Responses
{
    public class AttendanceResponse
    {
        public int Id { get; set; }
        // Populated only for admin clients. For employees the property "Employee" stays null
        public EmployeeResponse? Employee { get; set; }
        public DateOnly Date { get; set; }
        public DateTime? DateTimeEntered { get; set; }
        public DateTime? DateTimeLeft { get; set; }
        public decimal? WorkedHours { get; set; }
        public string? CorrectionReason { get; set; } = string.Empty;

        public class EmployeeResponse
        {
            public int Id { get; set; }
            public UserResponse? User { get; set; } 
            public DepartmentResponse? Department { get; set; }
        }

        public class UserResponse
        {
            public int Id { get; set; }
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
        }

        public class DepartmentResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
        }
    }
}
