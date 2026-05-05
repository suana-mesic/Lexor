namespace Lexor.Model.SearchObjects
{
    public class RoleSearchObject:BaseSearchObject
    {
        public string? Name { get; set; }
        public bool? OnlyActive { get; set; } //if true then show only active roles
    }
}
