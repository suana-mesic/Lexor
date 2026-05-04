using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class Contract
    {
        [Key]
        public int Id { get; set; }

        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        public int ContractTypeId { get; set; }

        [ForeignKey("ContractTypeId")]
        public ContractType ContractType { get; set; } = null!;

        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal BrutoSalary { get; set; }

        public int WorkHoursPerDay { get; set; } = 8;

        public bool IsActive { get; set; } = true;
    }
}
