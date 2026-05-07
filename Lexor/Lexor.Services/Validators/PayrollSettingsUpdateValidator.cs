using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class PayrollSettingsUpdateValidator : AbstractValidator<PayrollSettingsUpdateRequest>
    {
        public PayrollSettingsUpdateValidator()
        {
            RuleFor(x => x.ValidTo)
                .GreaterThan(x => x.ValidFrom).WithMessage("Datum važenja do mora biti nakon datuma važenja od.")
                .When(x => x.ValidFrom.HasValue && x.ValidTo.HasValue);

            RuleFor(x => x.WorkDaysDescription)
                .NotEmpty().WithMessage("Radni dani u sedmici su obavezni.")
                .MaximumLength(50).WithMessage("Radni dani u sedmici ne mogu imati više od 50 karaktera.")
                .When(x => x.WorkDaysDescription != null);

            RuleFor(x => x.OvertimeMultiplier)
                .GreaterThan(0).WithMessage("Koeficijent prekovremenih mora biti veći od 0.")
                .When(x => x.OvertimeMultiplier.HasValue);

            RuleFor(x => x.PersonalDeduction)
                .GreaterThanOrEqualTo(0).WithMessage("Lični odbitak mora biti veći ili jednak 0.")
                .When(x => x.PersonalDeduction.HasValue);

            RuleFor(x => x.PioMioRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa PIO/MIO mora biti između 0 i 100.")
                .When(x => x.PioMioRate.HasValue);

            RuleFor(x => x.HealthInsuranceRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa zdravstvenog osiguranja mora biti između 0 i 100.")
                .When(x => x.HealthInsuranceRate.HasValue);

            RuleFor(x => x.UnemploymentRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa za nezaposlene mora biti između 0 i 100.")
                .When(x => x.UnemploymentRate.HasValue);

            RuleFor(x => x.IncomeTaxRate)
                .InclusiveBetween(0m, 100m).WithMessage("Porez na dohodak mora biti između 0 i 100.")
                .When(x => x.IncomeTaxRate.HasValue);
        }
    }
}
