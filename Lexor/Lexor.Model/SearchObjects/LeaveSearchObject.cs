namespace Lexor.Model.SearchObjects
{
    public class LeaveSearchObject : BaseSearchObject
    {
        public int? EmployeeId { get; set; }
        public string? EmployeeName { get; set; }
        public int? LeaveTypeId { get; set; }
        public string? State { get; set; }
    }
}
