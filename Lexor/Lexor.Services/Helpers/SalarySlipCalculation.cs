using Lexor.Services.Database;

namespace Lexor.Services.Helpers
{
    internal static class SalarySlipCalculation
    {
        public static int GetWorkingDaysInMonth(int year, int month, PayrollSettings settings)
        {
            var totalDays = DateTime.DaysInMonth(year, month);
            var count = 0;
            for (var d = 1; d <= totalDays; d++)
            {
                var dow = new DateTime(year, month, d).DayOfWeek;
                if (settings.IsWorkDay(dow))
                    count++;
            }
            return count;
        }

        public static string GetMonthName(int monthId)
        {
            Dictionary<int, string> months = new Dictionary<int, string>()
             {
                 {1, "Januar" },
                 {2, "Februar" },
                 {3, "Mart" },
                 {4, "April" },
                 {5, "Maj" },
                 {6, "Juni" },
                 {7, "Juli" },
                 {8, "August" },
                 {9, "Septembar" },
                 {10, "Oktobar" },
                 {11, "Novembar" },
                 {12, "Decembar" },
            };
            return months.TryGetValue(monthId, out string value) ? value : "nepoznato";
        }
    }
}
