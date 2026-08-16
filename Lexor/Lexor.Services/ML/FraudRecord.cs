namespace Lexor.Services.ML
{
    // One attendance record: its ML features/label plus the metadata the charts need.
    public class FraudRecord
    {
        public FraudSample Sample { get; set; } = new();
        public DateOnly Date { get; set; }     // used to group detected frauds by month / weekday
        public int EmployeeId { get; set; }
    }
}
