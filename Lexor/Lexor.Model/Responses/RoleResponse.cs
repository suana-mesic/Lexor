namespace Lexor.Model.Responses
{
    public class RoleResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public bool IsActive { get; set; }
        public int UserCount { get; set; }
    }
}
