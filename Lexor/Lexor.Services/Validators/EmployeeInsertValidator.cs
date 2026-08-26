using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Helpers;

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
                .Must(dob => dob <= DateTime.UtcNow.AddYears(-18))
                .WithMessage("Uposlenik mora imati najmanje 18 godina.");

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
                .NotEmpty().WithMessage("Datum zaposlenja je obavezan.")
                .LessThanOrEqualTo(DateTime.UtcNow)
                .WithMessage("Datum zaposlenja ne može biti u budućnosti.")
                .GreaterThan(x => x.DateOfBirth)
                .WithMessage("Datum zaposlenja mora biti nakon datuma rođenja.");
        }
    }

    public class EmployeeUserInsertValidator : AbstractValidator<EmployeeInsertRequest.UserInsertRequest>
    {
        public EmployeeUserInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Ime je obavezno.")
                .MaximumLength(50).WithMessage("Ime ne može imati više od 50 karaktera.")
                .Matches(@"^[A-Za-zČčĆćŽžŠšĐđ -]+$")
                .WithMessage("Ime može sadržavati samo slova, razmak i crticu.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Prezime je obavezno.")
                .MaximumLength(50).WithMessage("Prezime ne može imati više od 50 karaktera.")
                .Matches(@"^[A-Za-zČčĆćŽžŠšĐđ -]+$")
                .WithMessage("Prezime može sadržavati samo slova, razmak i crticu.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Email mora biti validna email adresa.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .Matches(@"^(\+387|0)(\s*\d){8,9}$")
                .WithMessage("Unesite validan broj telefona (npr. 062 123 456 ili +387 62 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.ProfileImageBase64).ValidImage("Profilna slika");
        }
    }
}
