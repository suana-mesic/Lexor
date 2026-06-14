namespace Lexor.Model.Responses
{
    public class AttendanceSummaryResponse
    {
        public decimal TodayWorkedHours { get; set; }
        public decimal MonthTotalHours { get; set; }
        public double MonthAttendanceRate { get; set; }
        public string TodayStatus { get; set; } = string.Empty;
    }
}
