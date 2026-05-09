namespace Lexor.Model.Responses
{
    public class ScanResponse
    {
        public string Status { get; set; } = string.Empty;        // "ENTERED" | "LEFT" | "REJECTED"
        public string LedColor { get; set; } = string.Empty;      // "GREEN" | "RED" | "OFF"
        public bool Buzzer { get; set; }
        public string Message { get; set; } = string.Empty;       // user-readable message
        public int? EmployeeId { get; set; }
        public string? EmployeeFullName { get; set; }
        public DateTime? DateTimeEntered { get; set; }
        public DateTime? DateTimeLeft { get; set; }
    }
}
