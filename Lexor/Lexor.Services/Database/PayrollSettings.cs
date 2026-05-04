using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class PayrollSettings
    {
        [Key]
        public int Id { get; set; }

        public DateTime ValidFrom { get; set; }

        public DateTime? ValidTo { get; set; }

        [Required]
        [MaxLength(50)]
        public string WorkDaysDescription { get; set; } = "Pon-Pet";

        [Column(TypeName = "decimal(5,2)")]
        public decimal OvertimeMultiplier { get; set; } = 1.30m;

        [Column(TypeName = "decimal(18,2)")]
        public decimal PersonalDeduction { get; set; } = 300m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal PioMioRate { get; set; } = 17m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal HealthInsuranceRate { get; set; } = 12.5m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal UnemploymentRate { get; set; } = 1.5m;

        [Column(TypeName = "decimal(5,2)")]
        public decimal IncomeTaxRate { get; set; } = 10m;

        public ICollection<SalarySlip> SalarySlips { get; set; } = new List<SalarySlip>();
    }
}
