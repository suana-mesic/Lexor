namespace Lexor.Model.Responses
{
    public class RFIDResponse
    {
        public int Id { get; set; }
        public EmployeeResponse Employee { get; set; } = null!;
        public string Uid { get; set; } = string.Empty;
        public DateTime AssignedAt { get; set; }
        public DateTime? DeactivatedAt { get; set; }
        public bool IsActive { get; set; }

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
