using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Lexor.Model.Enums;

namespace Lexor.Services.Database
{
    public class Leave
    {
        [Key]
        public int Id { get; set; }

        public int EmployeeId { get; set; }

        [ForeignKey("EmployeeId")]
        public Employee Employee { get; set; } = null!;

        public int LeaveTypeId { get; set; }

        [ForeignKey("LeaveTypeId")]
        public LeaveType LeaveType { get; set; } = null!;

        public DateOnly DateFrom { get; set; }

        public DateOnly DateTo { get; set; }

        public int NumberOfDays { get; set; }

        [Required]
        [MaxLength(1000)]
        public string Reason { get; set; } = string.Empty;

        //public LeaveStatus Status { get; set; } = LeaveStatus.Pending;
        public string? State { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int? ApprovedByAdminId { get; set; }

        [ForeignKey("ApprovedByAdminId")]
        public User? ApprovedByAdmin { get; set; }

        public DateTime? ApprovedAt { get; set; }

        public int? RejectedByAdminId { get; set; }

        [ForeignKey("RejectedByAdminId")]
        public User? RejectedByAdmin { get; set; }

        public DateTime? RejectedAt { get; set; }

        [MaxLength(1000)]
        public string? RejectionReason { get; set; }

        public int? CancelledByUserId { get; set; }

        [ForeignKey("CancelledByUserId")]
        public User? CancelledByUser { get; set; }

        public DateTime? CancelledAt { get; set; }
    }
}
