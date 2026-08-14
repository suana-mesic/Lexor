using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;


namespace Lexor.Services.StateMachine.SalarySlipStateMachine
{
    public class ApprovedSalarySlipState : BaseSalarySlipState
    {
        public ApprovedSalarySlipState(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor, IServiceProvider serviceProvider) : base(dbContext, mapper, userAccessor, serviceProvider) { }
        public override async Task<SalarySlipResponse> MarkSingleSalaryAsPaid(SalarySlipPaySingleRequest request)
        {
            var approvedSalarySlipState = nameof(ApprovedSalarySlipState);

            var approvedSalary = await _dbContext.Set<SalarySlip>()
              .Include(ss => ss.Employee).ThenInclude(e => e.User)
              .Include(ss => ss.Items)
               .Where(ss => ss.Month == request.Month
               && ss.Year == request.Year
               && ss.EmployeeId == request.EmployeeId
               && ss.State == approvedSalarySlipState)
               .FirstOrDefaultAsync();

            if (approvedSalary == null)
                throw new BusinessException("Evidencija o plati ne postoji.");

            // Separation of duties (four-eyes): the person who approved a payslip must not be the
            // one who pays it out. Only enforced for an authenticated user (the seeder pays as the
            // system with no user id, so it is exempt).
            var payerId = _userAccessor.GetUserId();
            if (payerId != null && approvedSalary.MarkedAsApprovedByAdminId == payerId)
                throw new BusinessException(
                    "Ne možete isplatiti platu koju ste sami odobrili. Isplatu mora izvršiti druga osoba.");

            approvedSalary.State = nameof(PaidSalarySlipState);
            approvedSalary.PaidAt = DateTime.UtcNow;
            approvedSalary.MarkedAsPaidByAdminId = _userAccessor.GetUserId();

            await _dbContext.SaveChangesAsync();

            return _mapper.Map<SalarySlipResponse>(approvedSalary);
        }
        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(MarkSingleSalaryAsPaid) };
        }
    }
}
