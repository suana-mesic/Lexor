namespace Lexor.Services.ML
{
    public class FraudSample
    {
        public float ArrivalMinutes { get; set; }      // check-in time as minutes past midnight (08:30 -> 510)
        public float DepartureMinutes { get; set; }    // check-out time as minutes past midnight
        public float WorkedHours { get; set; }         // hours actually worked that day
        public float DepartureEditCount { get; set; }  // how many times the leave time was overwritten
        public float ArrivalDeviation { get; set; }    // arrival minus this employee's average arrival
        public float DepartureDeviation { get; set; }  // departure minus this employee's average departure
        public bool IsFraud { get; set; }              // label: what the model learns to predict
        public float Weight { get; set; } = 1f;        // per-row training weight (balances the rare class)
    }
}
