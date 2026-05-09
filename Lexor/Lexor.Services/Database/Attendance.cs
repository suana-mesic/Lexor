using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class Attendance
    {
        [Key]
        public int Id { get; set; }

        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        public int RfidCardId { get; set; }

        [ForeignKey("RfidCardId")]
        public RfidCard RfidCard { get; set; } = null!;

        public DateOnly Date { get; set; }

        public DateTime? DateTimeEntered { get; set; }

        public DateTime? DateTimeLeft { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? WorkedHours { get; set; }

        public bool IsCorrected { get; set; } = false;

        [MaxLength(500)]
        public string? CorrectionReason { get; set; }

        public int? UpdatedByUserId { get; set; }

        public User? UpdatedByUser { get; set; }
    }
}
