namespace Lexor.Model.Requests
{
    public class RFIDInsertRequest
    {
        public int EmployeeId { get; set; }
        public string Uid { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
    }
}
