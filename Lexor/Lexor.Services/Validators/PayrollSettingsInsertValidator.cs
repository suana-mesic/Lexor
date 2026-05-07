using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class PayrollSettingsInsertValidator : AbstractValidator<PayrollSettingsInsertRequest>
    {
        public PayrollSettingsInsertValidator()
        {
            RuleFor(x => x.ValidFrom)
                .NotEmpty().WithMessage("Datum važenja od je obavezan.");

            RuleFor(x => x.WorkDaysDescription)
                .NotEmpty().WithMessage("Radni dani u sedmici su obavezni.")
                .MaximumLength(50).WithMessage("Radni dani u sedmici ne mogu imati više od 50 karaktera.");

            RuleFor(x => x.OvertimeMultiplier)
                .GreaterThan(0).WithMessage("Koeficijent prekovremenih mora biti veći od 0.");

            RuleFor(x => x.PersonalDeduction)
                .GreaterThanOrEqualTo(0).WithMessage("Lični odbitak mora biti veći ili jednak 0.");

            RuleFor(x => x.PioMioRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa PIO/MIO mora biti između 0 i 100.");

            RuleFor(x => x.HealthInsuranceRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa zdravstvenog osiguranja mora biti između 0 i 100.");

            RuleFor(x => x.UnemploymentRate)
                .InclusiveBetween(0m, 100m).WithMessage("Stopa za nezaposlene mora biti između 0 i 100.");

            RuleFor(x => x.IncomeTaxRate)
                .InclusiveBetween(0m, 100m).WithMessage("Porez na dohodak mora biti između 0 i 100.");
        }
    }
}
