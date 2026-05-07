namespace Lexor.Model.Requests
{
    public class RFIDUpdateRequest
    {
        public int? EmployeeId { get; set; }

        public string? Uid { get; set; }

        public DateTime? DeactivatedAt { get; set; }

        public bool? IsActive { get; set; } = true;
    }
}
