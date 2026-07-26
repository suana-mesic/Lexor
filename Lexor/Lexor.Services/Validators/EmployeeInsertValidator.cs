using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class EmployeeInsertValidator : AbstractValidator<EmployeeInsertRequest>
    {
        public EmployeeInsertValidator()
        {
            RuleFor(x => x.User)
                .NotNull().WithMessage("Podaci o korisniku su obavezni.")
                .SetValidator(new EmployeeUserInsertValidator());

            RuleFor(x => x.DateOfBirth)
                .NotEmpty().WithMessage("Datum rođenja je obavezan.")
                .LessThan(DateTime.UtcNow).WithMessage("Datum rođenja mora biti u prošlosti.");

            RuleFor(x => x.Address)
                .NotEmpty().WithMessage("Adresa je obavezna.")
                .MaximumLength(200).WithMessage("Adresa ne može imati više od 200 karaktera.");

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("Grad je obavezan.");

            RuleFor(x => x.DepartmentId)
                .GreaterThan(0).WithMessage("Odjel je obavezan.");

            RuleFor(x => x.PositionId)
                .GreaterThan(0).WithMessage("Pozicija je obavezna.");

            RuleFor(x => x.HireDate)
                .NotEmpty().WithMessage("Datum zaposlenja je obavezan.");
        }
    }

    public class EmployeeUserInsertValidator : AbstractValidator<EmployeeInsertRequest.UserInsertRequest>
    {
        public EmployeeUserInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Ime je obavezno.")
                .MaximumLength(50).WithMessage("Ime ne može imati više od 50 karaktera.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Prezime je obavezno.")
                .MaximumLength(50).WithMessage("Prezime ne može imati više od 50 karaktera.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Email mora biti validna email adresa.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.PhoneNumber)
                .Matches(@"^\+?[0-9\s]{8,20}$")
                .WithMessage("Telefon mora biti u ispravnom formatu (npr. 062 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));
        }
    }
}
