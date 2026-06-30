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

        public ICollection<Position> Positions { get; set; } = new List<Position>();
    }
}
