namespace Lexor.Model.Requests
{
    public class AttendanceInsertRequest
    {
        public int EmployeeId { get; set; }

        public int RfidCardId { get; set; }

        public DateOnly Date { get; set; }

        public DateTime? DateTimeEntered { get; set; }

        public DateTime? DateTimeLeft { get; set; }

        public decimal? WorkedHours { get; set; }

        public bool IsCorrected { get; set; } = false;

        public string? CorrectionReason { get; set; } = string.Empty;

        public int? CorrectedByAdminId { get; set; }

    }
}
