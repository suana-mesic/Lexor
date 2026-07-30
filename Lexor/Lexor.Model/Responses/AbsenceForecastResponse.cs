namespace Lexor.Model.Responses
{
    public class AbsenceForecastResponse
    {
        public List<AbsenceForecastDayResponse> Days { get; set; } = new();
        public List<DepartmentAbsenceForecastResponse> Departments { get; set; } = new();
        public List<EmployeeAbsenceRiskResponse> Employees { get; set; } = new();
        public AbsenceModelMetricsResponse? Metrics { get; set; }
    }

    public class AbsenceForecastDayResponse
    {
        public DateOnly Date { get; set; }

        // Sum of per-employee absence probabilities = expected number of absentees that day.
        public double ExpectedAbsences { get; set; }
    }

    public class DepartmentAbsenceForecastResponse
    {
        public string Department { get; set; } = string.Empty;
        public int EmployeeCount { get; set; }

        // Expected person-days of absence in the requested period.
        public double ExpectedAbsenceDays { get; set; }
    }

    public class EmployeeAbsenceRiskResponse
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Department { get; set; } = string.Empty;
        public double AverageProbability { get; set; }
        public bool HasPlannedLeave { get; set; }
    }

    public class AbsenceModelMetricsResponse
    {
        public double Auc { get; set; }
        public double F1 { get; set; }
        public double BestThreshold { get; set; }
        public double Precision { get; set; }
        public double Recall { get; set; }
        public double Accuracy { get; set; }
        public int SampleCount { get; set; }
    }
}
