using System.ComponentModel.DataAnnotations;

namespace Lexor.Model.Requests
{
    public class RoleUpdateRequest
    {
        public string? Name { get; set; }
        public string? Description { get; set; }
        public bool? IsActive { get; set; }
    }
}
