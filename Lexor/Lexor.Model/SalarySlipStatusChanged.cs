namespace Lexor.Model
{
    /// <summary>
    /// Published when a payslip changes state (approved / paid) so the worker can create the
    /// employee's notification. Mirrors <see cref="LeaveStatusChanged"/>.
    /// </summary>
    public class SalarySlipStatusChanged
    {
        public int SalarySlipId { get; set; }
        public int EmployeeId { get; set; }

        /// State-machine class name, e.g. "ApprovedSalarySlipState".
        public string NewState { get; set; } = string.Empty;

        /// Human-readable payroll period, e.g. "Mart 2026". Carried in the message so the
        /// worker does not need the month-name helper, which is internal to Lexor.Services.
        public string Period { get; set; } = string.Empty;
    }
}
