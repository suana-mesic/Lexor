using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Lexor.Model.Enums;

namespace Lexor.Services.Database
{
    public class SalarySlip
    {
        [Key]
        public int Id { get; set; }

        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        public int PayrollSettingsId { get; set; }

        [ForeignKey("PayrollSettingsId")]
        public PayrollSettings PayrollSettings { get; set; } = null!;

        public int Year { get; set; }

        public int Month { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal BrutoSalary { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal AdjustedBruto { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalContributions { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal TaxBase { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Tax { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal NetSalary { get; set; }

        public SalarySlipStatus Status { get; set; } = SalarySlipStatus.Pending;

        public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;

        public DateTime? PaidAt { get; set; }

        public int? MarkedAsPaidByAdminId { get; set; }

        [ForeignKey("MarkedAsPaidByAdminId")]
        public User? MarkedAsPaidByAdmin { get; set; }

        public ICollection<SalarySlipItem> Items { get; set; } = new List<SalarySlipItem>();
    }
}
