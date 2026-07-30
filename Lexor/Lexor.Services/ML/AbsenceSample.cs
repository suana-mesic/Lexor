namespace Lexor.Services.ML
{
    /// <summary>
    /// One training/prediction sample: a single employee on a single working day.
    /// </summary>
    public class AbsenceSample
    {
        // Employee identity as a category, so the model can learn personal seasonal patterns.
        public string Employee { get; set; } = string.Empty;
        // Categorical features (encoded via one-hot during training).
        public string DayOfWeek { get; set; } = string.Empty;
        public string Month { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;

        // How often this employee was absent before this day (0..1).
        public float HistoricalAbsenceRate { get; set; }

        // How often this employee was absent in the last 30 days (0..1).
        public float RecentAbsenceRate { get; set; }

        // How often this employee was absent in THIS calendar month in previous years (0..1).
        public float MonthSeasonRate { get; set; }

        // 1 when a PLANNED leave (annual/paid/unpaid - approved in advance) covers this day.
        // Sick leave is deliberately NOT included: it is not known in advance, so the model
        // must learn sick-season patterns from the employee/month features instead.
        public float OnPlannedLeave { get; set; }

        // 1 when the previous working day was an absence (sickness tends to last).
        public float PrevWorkdayAbsent { get; set; }

        // How many of the previous 5 working days the employee was absent (0..5).
        public float AbsencesInLast5Workdays { get; set; }

        // Label - what the model learns to predict: was the employee absent that day?
        public bool IsAbsent { get; set; }
        
    }
}
