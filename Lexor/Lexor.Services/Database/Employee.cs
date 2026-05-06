using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class Employee
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User User { get; set; } = null!;

        public DateTime DateOfBirth { get; set; }

        [Required]
        [MaxLength(200)]
        public string Address { get; set; } = string.Empty;

        public int CityId { get; set; }

        [ForeignKey("CityId")]
        public City City { get; set; } = null!;

        public int DepartmentId { get; set; }

        [ForeignKey("DepartmentId")]
        public Department Department { get; set; } = null!;

        public int PositionId { get; set; }

        [ForeignKey("PositionId")]
        public Position Position { get; set; } = null!;

        public DateTime HireDate { get; set; }

        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public int CreatedByUserId { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public int? UpdatedByUserId { get; set; }

        public ICollection<Contract> Contracts { get; set; } = new List<Contract>();

        public ICollection<RfidCard> RfidCards { get; set; } = new List<RfidCard>();

        public ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();

        public ICollection<LeaveRequest> LeaveRequests { get; set; } = new List<LeaveRequest>();

        public ICollection<SalarySlip> SalarySlips { get; set; } = new List<SalarySlip>();

        public ICollection<ChatConversation> ChatConversations { get; set; } = new List<ChatConversation>();

        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    }
}
