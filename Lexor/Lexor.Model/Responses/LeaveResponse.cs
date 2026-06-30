namespace Lexor.Model.Responses
{
    public class LeaveResponse
    {
        public int Id { get; set; }
        // Populated only for admin clients. For employees the property "Employee" stays null
        public EmployeeResponse? Employee { get; set; }
        public LeaveTypeResponse LeaveType { get; set; } = null!;
        public DateOnly DateFrom { get; set; }
        public DateOnly DateTo { get; set; }
        public int NumberOfDays { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string? State { get; set; }
        public string? RejectionReason { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<string> AllowedActions { get; set; } = new List<string>();
        public class LeaveTypeResponse
        {
            public int Id { get; set; }
            public string Name { get; set; } = string.Empty;
            public bool IsPaid { get; set; }
        }

        public class EmployeeResponse
        {
            public int Id { get; set; }
            public UserResponse User { get; set; } = null!;
        }

        public class UserResponse
        {
            public int Id { get; set; }
            public string FirstName { get; set; } = string.Empty;
            public string LastName { get; set; } = string.Empty;
        }
    }
}
