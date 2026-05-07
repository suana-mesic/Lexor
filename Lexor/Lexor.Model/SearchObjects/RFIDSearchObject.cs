using Lexor.Model.Enums;

namespace Lexor.Model.SearchObjects
{
    public class RFIDSearchObject : BaseSearchObject
    {
        public int? EmployeeId { get; set; }
        public ActivityStatus? ActivityStatus { get; set; }
    }
}
