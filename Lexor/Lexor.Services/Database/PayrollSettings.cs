using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class PayrollSettings
    {
        [Key]
        public int Id { get; set; }
        [Column(TypeName = "time")]
        public TimeOnly WorkStartTime { get; set; } = new TimeOnly(9, 0);
        public DateTime ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }

        // Mon-Fri = 31 (bits 0-4), Mon-Sat = 63 (bits 0-5)
        public int WorkDaysMask { get; set; } = 31;

        // Mon = 1, Tue = 2, Wed = 3, Thu = 4, Fri = 5, Sat = 6, Sun = 0
        // day = Mon = 1
        // bitPosition = 1-1=0
        // bit = 1 << 0 -> 00000001 (num:1) -> 00000001 (num:1)
        // logical operation 31 (WorkDaysMask) & 1
        // 00011111
        // &
        // 00000001
        // result -> true (Monday is Working Day)

        // day = Sun = 0
        // bitPosition = 6
        // bit = 1 << 6 01000000
        // logical operation 31 (WorkDaysMask) & 64
        // 00011111
        // &
        // 01000000
        // result = false
        public bool IsWorkDay(DayOfWeek day)
        {
            int bitPosition = day == DayOfWeek.Sunday ? 6 : (int)day - 1;
            int bit = 1 << bitPosition;
            return (WorkDaysMask & bit) != 0;
        }

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
