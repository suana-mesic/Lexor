namespace Lexor.Model.Responses
{
    /// <summary>
    /// One employee's attendance totals for a single month, as shown in the HR attendance
    /// report. Everything here is aggregated in the database - the report never carries
    /// individual attendance rows.
    /// </summary>
    public class AttendanceReportRow
    {
        public int EmployeeId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string DepartmentName { get; set; } = string.Empty;

        /// <summary>Days with a scanned attendance record.</summary>
        public int PresentDays { get; set; }

        /// <summary>Working days covered by an approved leave.</summary>
        public int LeaveDays { get; set; }

        /// <summary>Working days with neither an attendance record nor an approved leave.</summary>
        public int MissingDays { get; set; }

        public decimal TotalHours { get; set; }
        public decimal AverageHours { get; set; }

        /// <summary>Average arrival time as minutes from midnight; null when never present.</summary>
        public int? AverageArrivalMinutes { get; set; }

        /// <summary>Records HR corrected after the fact - the audit-relevant count.</summary>
        public int CorrectedRecords { get; set; }
    }

    public class AttendanceReportResponse
    {
        public int Year { get; set; }
        public int Month { get; set; }

        /// <summary>Working days (Mon-Fri) in the reported month.</summary>
        public int WorkingDays { get; set; }

        public List<AttendanceReportRow> Rows { get; set; } = new();
    }
}
