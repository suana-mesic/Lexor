using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.StateMachine.SalarySlipStateMachine
{
    public class PendingSalarySlipState : BaseSalarySlipState
    {
        public PendingSalarySlipState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider)
            : base(dbContext, mapper, userAccessor, serviceProvider)
        {
        }

        public async override Task<SalarySlipResponse> RecalculateSingleSalary(SalarySlipSingleRecalculationRequest request)
        {
            var existingSlip = await _dbContext.Set<SalarySlip>()
                .Where(ss => ss.EmployeeId == request.EmployeeId
                && ss.Year == request.Year
                && ss.Month == request.Month)
                .FirstOrDefaultAsync();


            if (existingSlip == null)
                throw new InvalidOperationException("Evidencija o plati ne postoji.");

            // 1) Remove old slip — Items cascade automatically via FK constraint
            _dbContext.Set<SalarySlip>().Remove(existingSlip);
            await _dbContext.SaveChangesAsync();

            // 2) Direct call to shared helper — no self-dispatch needed
            var count = await GenerateSlipsCore(new SalarySlipCalculationRequest
            {
                EmployeeId = request.EmployeeId,
                Month = request.Month,
                Year = request.Year
            });

            if (count == 0)
                throw new InvalidOperationException("Nije moguće generisati novi obračun za odabranog uposlenika.");

            // 3) Load and return the new slip with everything needed for response
            var newSlip = await _dbContext.Set<SalarySlip>()
                .Include(ss => ss.Employee).ThenInclude(e => e.User)
                .Include(ss => ss.Items)
                .FirstOrDefaultAsync(ss => ss.EmployeeId == request.EmployeeId
                                        && ss.Year == request.Year
                                        && ss.Month == request.Month);

            return _mapper.Map<SalarySlipResponse>(newSlip);
        }

        public override async Task<SalarySlipResponse> MarkSingleSalaryAsApproved(SalarySlipApproveSingleRequest request)
        {
            var pendingStateNameSingle = nameof(PendingSalarySlipState);

            var pendingSalary = await _dbContext.Set<SalarySlip>()
              .Include(ss => ss.Employee).ThenInclude(e => e.User)
              .Include(ss => ss.Items)
               .Where(ss => ss.Month == request.Month
               && ss.Year == request.Year
               && ss.EmployeeId == request.EmployeeId
               && ss.State == pendingStateNameSingle)
               .FirstOrDefaultAsync();

            if (pendingSalary == null)
                throw new InvalidOperationException("Evidencija o plati ne postoji.");

            pendingSalary.State = nameof(ApprovedSalarySlipState);
            pendingSalary.ApprovedAt = DateTime.UtcNow;
            pendingSalary.MarkedAsApprovedByAdminId = _userAccessor.GetUserId();

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<SalarySlipResponse>(pendingSalary);
        }
        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(RecalculateSingleSalary), nameof(MarkSingleSalaryAsApproved) };
        }
    }
}
