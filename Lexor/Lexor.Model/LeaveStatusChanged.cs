namespace Lexor.Model
{
    public class LeaveStatusChanged
    {
        public int LeaveId { get; set; }
        public int EmployeeId { get; set; }
        public string NewState { get; set; } = string.Empty; 
        public string? RejectionReason { get; set; }
    }
}
