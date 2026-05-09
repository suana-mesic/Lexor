namespace Lexor.Model.Responses
{
    public class AttendanceResponse
    {
        public int Id { get; set; }
        public EmployeeResponse Employee { get; set; } = null!;
        public DateOnly Date { get; set; }
        public DateTime? DateTimeEntered { get; set; }
        public DateTime? DateTimeLeft { get; set; }
        public decimal? WorkedHours { get; set; }
        public string? CorrectionReason { get; set; } = string.Empty;

        public class EmployeeResponse
        {
            public int Id { get; set; }
            public UserResponse User { get; set; } = null!;
            public DepartmentResponse Department { get; set; } = null!;
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
