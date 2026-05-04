using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    public class Country
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public ICollection<City> Cities { get; set; } = new List<City>();
    }
}
