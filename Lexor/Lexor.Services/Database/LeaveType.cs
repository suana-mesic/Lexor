using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    public class LeaveType
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        public bool IsPaid { get; set; }

        public ICollection<LeaveRequest> LeaveRequests { get; set; } = new List<LeaveRequest>();
    }
}
