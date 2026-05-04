using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Lexor.Model.Enums;

namespace Lexor.Services.Database
{
    public class SalarySlipItem
    {
        [Key]
        public int Id { get; set; }

        public int SalarySlipId { get; set; }

        [ForeignKey("SalarySlipId")]
        public SalarySlip SalarySlip { get; set; } = null!;

        public SalarySlipItemType ItemType { get; set; }

        [Required]
        [MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(300)]
        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? Quantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal? Rate { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? Multiplier { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }
    }
}
