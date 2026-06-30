using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class EmployeeUpdateValidator : AbstractValidator<EmployeeUpdateRequest>
    {
        public EmployeeUpdateValidator()
        {
            RuleFor(x => x.User!)
                .SetValidator(new EmployeeUserUpdateValidator())
                .When(x => x.User != null);

            RuleFor(x => x.DateOfBirth)
                .LessThan(DateTime.UtcNow).WithMessage("Datum rođenja mora biti u prošlosti.")
                .When(x => x.DateOfBirth.HasValue);

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Adresa ne može imati više od 200 karaktera.")
                .When(x => x.Address != null);

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("Grad je obavezan.")
                .When(x => x.CityId.HasValue);

            RuleFor(x => x.DepartmentId)
                .GreaterThan(0).WithMessage("Odjel je obavezan.")
                .When(x => x.DepartmentId.HasValue);

            RuleFor(x => x.PositionId)
                .GreaterThan(0).WithMessage("Pozicija je obavezna.")
                .When(x => x.PositionId.HasValue);
        }
    }

    public class EmployeeUserUpdateValidator : AbstractValidator<EmployeeUpdateRequest.UserUpdateRequest>
    {
        public EmployeeUserUpdateValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Ime ne može biti prazno.")
                .MaximumLength(50).WithMessage("Ime ne može imati više od 50 karaktera.")
                .When(x => x.FirstName != null);

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Prezime ne može biti prazno.")
                .MaximumLength(50).WithMessage("Prezime ne može imati više od 50 karaktera.")
                .When(x => x.LastName != null);

            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Korisničko ime ne može biti prazno.")
                .MaximumLength(100).WithMessage("Korisničko ime ne može imati više od 100 karaktera.")
                .When(x => x.Username != null);

            RuleFor(x => x.Email)
                .EmailAddress().WithMessage("Email mora biti validna email adresa.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.")
                .When(x => !string.IsNullOrWhiteSpace(x.Email));

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));
        }
    }
}
