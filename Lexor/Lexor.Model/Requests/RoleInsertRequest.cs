using System.ComponentModel.DataAnnotations;

namespace Lexor.Model.Requests
{
    public class RoleInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
    }
}
