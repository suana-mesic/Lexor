using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class SalarySlipAllRecalculationValidator:AbstractValidator<SalarySlipAllRecalculationRequest>
    {
        public SalarySlipAllRecalculationValidator()
        {
            RuleFor(x => x.Month)
               .InclusiveBetween(1, 12).WithMessage("Mjesec mora biti u rasponu od januara do decembra.");
            RuleFor(x => x.Year)
                .GreaterThan(1000).WithMessage("Godina obračuna mora biti veća od 1000.");
        }
    }
}
