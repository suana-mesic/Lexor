using System.Text.Json.Serialization;

namespace Lexor.Model.Requests
{
    public class LeaveInsertRequest
    {
        public int LeaveTypeId { get; set; }
        public DateOnly DateFrom { get; set; }
        public DateOnly DateTo { get; set; }
        public string Reason { get; set; } = string.Empty;
    }
}
