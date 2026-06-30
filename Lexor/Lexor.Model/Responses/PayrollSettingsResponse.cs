namespace Lexor.Model.Responses
{
    public class PayrollSettingsResponse
    {
        public int Id { get; set; }
        public DateTime ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
        public string WorkDaysDescription { get; set; } = string.Empty;
        public int WorkDaysMask { get; set; }
        public decimal OvertimeMultiplier { get; set; }
        public decimal PersonalDeduction { get; set; }
        public decimal PioMioRate { get; set; }
        public decimal HealthInsuranceRate { get; set; }
        public decimal UnemploymentRate { get; set; }
        public decimal IncomeTaxRate { get; set; }
    }
}
