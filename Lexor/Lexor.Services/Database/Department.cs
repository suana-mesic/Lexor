using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    public class Department
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public ICollection<Employee> Employees { get; set; } = new List<Employee>();
    }
}
