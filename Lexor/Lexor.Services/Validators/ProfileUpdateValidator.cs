using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ProfileUpdateValidator : AbstractValidator<ProfileUpdateRequest>
    {
        public ProfileUpdateValidator()
        {
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

            RuleFor(x => x.PhoneNumber)
                .Matches(@"^(\+387|0)(\s*\d){8,9}$")
                .WithMessage("Unesite validan broj telefona (npr. 062 123 456 ili +387 62 123 456).")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Adresa ne može imati više od 200 karaktera.")
                .When(x => x.Address != null);


        }
    }
}
