namespace Lexor.Model.Responses
{
    public class AttendaceSummaryResponse
    {
        public decimal TodayWorkedHours{ get; set; }
        public decimal MonthWorkedHours { get; set; }
        public double MonthAttendaceRate { get; set; }
        public string TodayStatus { get; set; }
    }
}
