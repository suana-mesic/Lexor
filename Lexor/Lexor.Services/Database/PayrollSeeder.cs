using Lexor.Model.Requests;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    /// <summary>
    /// Seeds a payroll history by running the REAL salary calculation for each completed
    /// month, starting from when payroll settings became valid. Reusing the service means
    /// amounts, contract coverage and settings all match the app's own logic — in particular
    /// a month in which an employee had no active contract produces no slip (the calculation
    /// skips it), so nobody is ever "paid" for a period without a contract. Older months are
    /// approved and paid; the most recent completed month is left pending so the accounting
    /// workflow can be demonstrated. Runs once, only on a fresh (payroll-less) database.
    /// </summary>
    public static class PayrollSeeder
    {
        public static async Task SeedAsync(ISalarySlipService salarySlipService, LexorDbContext db)
        {
            if (await db.Set<SalarySlip>().AnyAsync())
                return;

            // Payroll settings are valid from this date; earlier periods have no settings and
            // therefore cannot be calculated.
            var earliestSettings = await db.Set<PayrollSettings>()
                .OrderBy(ps => ps.ValidFrom)
                .Select(ps => ps.ValidFrom)
                .FirstOrDefaultAsync();
            if (earliestSettings == default)
                return;

            var start = new DateTime(earliestSettings.Year, earliestSettings.Month, 1);
            var now = DateTime.UtcNow;
            // The most recent completed month is intentionally NOT seeded, so demo data has no
            // in-progress ("na čekanju") payroll; the loop stops before it.
            var lastComplete = new DateTime(now.Year, now.Month, 1).AddMonths(-1);

            for (var period = start; period < lastComplete; period = period.AddMonths(1))
            {
                var generated = await salarySlipService.InsertOrRecalculateSalaries(
                    new SalarySlipCalculationRequest { Year = period.Year, Month = period.Month });
                if (generated == 0)
                    continue;

                // Every seeded month is fully settled (approved and paid).
                await salarySlipService.MarkAllSalariesAsApproved(
                    new SalarySlipApproveAllRequest { Year = period.Year, Month = period.Month });
                await salarySlipService.MarkAllSalariesAsPaid(
                    new SalarySlipPayAllRequest { Year = period.Year, Month = period.Month });
            }
        }
    }
}
