using Lexor.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.ML
{
    // Turns attendance rows into ML samples, computing each employee's personal baseline.
    public static class FraudSampleBuilder
    {
        public static async Task<List<FraudRecord>> BuildAsync(LexorDbContext db)
        {
            // Load only the fields we need, for records that have BOTH timestamps.
            var rows = await db.Attendances
                .Where(a => a.DateTimeEntered != null && a.DateTimeLeft != null)
                .Select(a => new
                {
                    a.EmployeeId,
                    a.Date,
                    a.DateTimeEntered,
                    a.DateTimeLeft,
                    a.WorkedHours,
                    a.DepartureEditCount,
                    a.IsFraud
                })
                .ToListAsync();

            // Local helper: clock time of a timestamp as minutes past midnight (08:30 -> 510).
            static double Minutes(DateTime? dt) => dt!.Value.TimeOfDay.TotalMinutes;


            // Each employee's average arrival/departure = their "normal" schedule.

            var avgByEmployee = rows
                            .GroupBy(r => r.EmployeeId)
                            .ToDictionary(
                                g => g.Key,
                                g => (
                                    Arrival: g.Average(r => Minutes(r.DateTimeEntered)),
                                    Departure: g.Average(r => Minutes(r.DateTimeLeft))
                                ));
            // Chronological order: the 80/20 split downstream cuts by time, so order matters here.
            // Each sample is wrapped in a FraudRecord so charts can group flags by date later.
            return rows
                .OrderBy(r => r.Date).ThenBy(r => r.DateTimeEntered)
                .Select(r =>
                {
                    var arrival = (float)Minutes(r.DateTimeEntered);
                    var departure = (float)Minutes(r.DateTimeLeft);
                    var avg = avgByEmployee[r.EmployeeId];
                    return new FraudRecord
                    {
                        Date = r.Date,
                        EmployeeId = r.EmployeeId,
                        Sample = new FraudSample
                        {
                            ArrivalMinutes = arrival,
                            DepartureMinutes = departure,
                            WorkedHours = (float)(r.WorkedHours ?? 0m),
                            DepartureEditCount = r.DepartureEditCount,
                            ArrivalDeviation = arrival - (float)avg.Arrival,       // + = later than usual
                            DepartureDeviation = departure - (float)avg.Departure, // - = earlier than usual
                            IsFraud = r.IsFraud
                        }
                    };
                })
                .ToList();
        }
    }
}
