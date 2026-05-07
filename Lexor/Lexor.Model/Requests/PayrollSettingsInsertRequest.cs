namespace Lexor.Model.Requests
{
    public class PayrollSettingsInsertRequest
    {
        public DateTime ValidFrom { get; set; }
        public string WorkDaysDescription { get; set; } = string.Empty;
        public decimal OvertimeMultiplier { get; set; }
        public decimal PersonalDeduction { get; set; }
        public decimal PioMioRate { get; set; }
        public decimal HealthInsuranceRate { get; set; }
        public decimal UnemploymentRate { get; set; }
        public decimal IncomeTaxRate { get; set; }
    }
}
