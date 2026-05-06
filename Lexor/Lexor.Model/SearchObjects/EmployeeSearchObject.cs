namespace Lexor.Model.SearchObjects
{
    public class EmployeeSearchObject:BaseSearchObject
    {
        public string? FullName { get; set; }
        public int? DepartmentId { get; set; }
        public bool? OnlyActive { get; set; }
    }
}
