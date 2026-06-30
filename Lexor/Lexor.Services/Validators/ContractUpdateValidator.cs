using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractUpdateValidator : AbstractValidator<ContractUpdateRequest>
    {
        public ContractUpdateValidator()
        {
            RuleFor(x => x.ContractTypeId)
                .GreaterThan(0).WithMessage("Tip ugovora je obavezno polje.");

            RuleFor(x => x.StartDate)
                .NotEmpty().WithMessage("Datum početka je obavezno polje.");

            RuleFor(x => x.EndDate)
                .GreaterThan(x => x.StartDate).WithMessage("Datum završetka mora biti nakon datuma početka.")
                .When(x => x.EndDate.HasValue);

            RuleFor(x => x.BrutoSalary)
                .GreaterThan(0).WithMessage("Bruto plata mora biti veća od 0.")
                .LessThanOrEqualTo(1_000_000m).WithMessage("Bruto plata ne može biti veća od 1.000.000 KM.");

            RuleFor(x => x.WorkHoursPerDay)
                .InclusiveBetween(1, 24).WithMessage("Broj radnih sati po danu mora biti između 1 i 24.");
        }
    }
}
