namespace Lexor.Model.Responses
{
    public class RFIDResponse
    {
        public int Id { get; set; }
        public RFIDEmployeeResponse Employee { get; set; } = null!;
        public string Uid { get; set; } = string.Empty;
        public DateTime AssignedAt { get; set; }
        public DateTime? DeactivatedAt { get; set; }
        public bool IsActive { get; set; }
    }

    public class RFIDEmployeeResponse
    {
        public int Id { get; set; }
        public RFIDUserResponse User { get; set; } = null!;
    }

    public class RFIDUserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
    }
}
