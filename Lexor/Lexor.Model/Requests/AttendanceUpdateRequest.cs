namespace Lexor.Model.Requests
{
    public class AttendanceUpdateRequest
    {
        public DateTime? DateTimeEntered { get; set; }
        public DateTime? DateTimeLeft { get; set; }
        public string CorrectionReason { get; set; } = string.Empty;
    }
}
