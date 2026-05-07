using Lexor.Model.Enums;

namespace Lexor.Model.SearchObjects
{
    public class RoleSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public ActivityStatus? ActivityStatus { get; set; }
    }
}
