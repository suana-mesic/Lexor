using Lexor.Model.Enums;

namespace Lexor.Model.SearchObjects
{
    public class EmployeeSearchObject : BaseSearchObject
    {
        public string? FullName { get; set; }
        public int? DepartmentId { get; set; }
        public ActivityStatus? ActivityStatus { get; set; }
    }
}
