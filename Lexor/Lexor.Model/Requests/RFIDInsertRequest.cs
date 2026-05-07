namespace Lexor.Model.Requests
{
    public class RFIDInsertRequest
    {
        public int EmployeeId { get; set; }
        public string Uid { get; set; } = string.Empty;
        public DateTime? DeactivatedAt { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
