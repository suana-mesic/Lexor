using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class SalarySlipSingleRecalculationValidator : AbstractValidator<SalarySlipSingleRecalculationRequest>
    {
        public SalarySlipSingleRecalculationValidator()
        {
            RuleFor(x=>x.EmployeeId)
               .GreaterThan(0).WithMessage("ID uposlenika mora biti veći od 0.");
            RuleFor(x => x.Month)
            .InclusiveBetween(1, 12).WithMessage("Mjesec mora biti u rasponu od januara do decembra.");
            RuleFor(x => x.Year)
                .GreaterThan(1000).WithMessage("Godina obračuna mora biti veća od 1000.");
        }
    }
}
