namespace Lexor.Model.SearchObjects
{
    public class AttendanceSearchObject : BaseSearchObject
    {
        public int? EmployeeId { get; set; }
        public DateOnly? FromDate { get; set; }
        public DateOnly? ToDate { get; set; }
        public int? DepartmentId { get; set; }
    }
}
