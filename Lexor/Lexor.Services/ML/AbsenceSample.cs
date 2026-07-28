namespace Lexor.Services.ML
{
    /// <summary>
    /// One training/prediction sample: a single employee on a single working day.
    /// </summary>
    public class AbsenceSample
    {
        // Categorical features (encoded via one-hot during training).
        public string DayOfWeek { get; set; } = string.Empty;
        public string Month { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;

        // How often this employee was absent before this day (0..1).
        public float HistoricalAbsenceRate { get; set; }

        // How often this employee was absent in the last 30 days (0..1).
        public float RecentAbsenceRate { get; set; }

        // 1 when an approved/completed leave covers this day (known in advance).
        public float OnApprovedLeave { get; set; }

        // 1 when the previous working day was an absence (sickness tends to last).
        public float PrevWorkdayAbsent { get; set; }

        // Label - what the model learns to predict: was the employee absent that day?
        public bool IsAbsent { get; set; }
    }
}
