using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;

namespace Lexor.Services
{
    // Salary slip service contract. Currently exposes only read operations;
    // domain actions (RunCalculation, MarkAsPaid, ...) will be added later.
    public interface ISalarySlipService : IBaseReadService<SalarySlipResponse, SalarySlipCalculationSearchObject>
    {
        public Task<int> RecalculateAllSalaries(SalarySlipAllRecalculationRequest request);
        public Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request);
        public Task<int> InsertOrRecalculateSalaries(SalarySlipCalculationRequest request);
        public Task<int> MarkAllSalariesAsApproved(SalarySlipApproveAllRequest request);
        public Task<SalarySlipResponse> MarkSingleSalaryAsApproved(SalarySlipApproveSingleRequest request);
        public Task<int> MarkAllSalariesAsPaid(SalarySlipPayAllRequest request);
        public Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request);
        public Task<(byte[] Bytes, string FileName)> GetSlipPdfAsync(int id);
        public Task<byte[]> GetMonthlyReportPdfAsync(int year, int month);
    }
}
