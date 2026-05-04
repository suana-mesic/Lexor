using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class RfidCard
    {
        [Key]
        public int Id { get; set; }

        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        [Required]
        [MaxLength(50)]
        public string Uid { get; set; } = string.Empty;

        public DateTime AssignedAt { get; set; } = DateTime.UtcNow;

        public DateTime? DeactivatedAt { get; set; }

        public bool IsActive { get; set; } = true;

        public ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();
    }
}
