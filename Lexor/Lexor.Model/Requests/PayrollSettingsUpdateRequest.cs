namespace Lexor.Model.Requests
{
    public class PayrollSettingsUpdateRequest
    {
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
        public string? WorkDaysDescription { get; set; }
        public decimal? OvertimeMultiplier { get; set; }
        public decimal? PersonalDeduction { get; set; }
        public decimal? PioMioRate { get; set; }
        public decimal? HealthInsuranceRate { get; set; }
        public decimal? UnemploymentRate { get; set; }
        public decimal? IncomeTaxRate { get; set; }
    }
}
