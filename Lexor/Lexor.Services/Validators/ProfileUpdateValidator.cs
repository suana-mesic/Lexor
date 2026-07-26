using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ProfileUpdateValidator : AbstractValidator<ProfileUpdateRequest>
    {
        public ProfileUpdateValidator()
        {
            RuleFor(x => x.Email)
                .EmailAddress().WithMessage("Email mora biti validna email adresa.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.")
                .When(x => !string.IsNullOrWhiteSpace(x.Email));

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.PhoneNumber)
                .Matches(@"^\+?[0-9\s]{8,20}$")
                .WithMessage("Telefon mora biti u ispravnom formatu (npr. 062 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Adresa ne može imati više od 200 karaktera.")
                .When(x => x.Address != null);


        }
    }
}
