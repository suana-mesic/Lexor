using Lexor.Model.Enums;

namespace Lexor.Model.SearchObjects
{
    public class UserSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? RoleName { get; set; }
        public ActivityStatus? ActivityStatus { get; set; }
    }
}
