using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ResetPasswordValidator : AbstractValidator<ResetPasswordRequest>
    {
        public ResetPasswordValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Unesite ispravan email.");

            RuleFor(x => x.Code)
                .NotEmpty().WithMessage("Kod je obavezan.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 znakova.");
        }
    }
}