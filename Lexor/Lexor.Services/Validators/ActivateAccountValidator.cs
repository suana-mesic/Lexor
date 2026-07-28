using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ActivateAccountValidator : AbstractValidator<ActivateAccountRequest>
    {
        public ActivateAccountValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Unesite ispravan email.");

            RuleFor(x => x.InvitationCode)
                .NotEmpty().WithMessage("Aktivacijski kod je obavezan.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 znakova.");
        }
    }
}