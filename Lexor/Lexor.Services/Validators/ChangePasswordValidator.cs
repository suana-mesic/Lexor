using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ChangePasswordValidator : AbstractValidator<ChangePasswordRequest>
    {
        public ChangePasswordValidator()
        {
            RuleFor(x => x.OldPassword)
                .NotEmpty().WithMessage("Trenutna lozinka je obavezna.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("Nova lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Nova lozinka mora imati najmanje 6 znakova.");

            RuleFor(x => x.ConfirmNewPassword)
                .Equal(x => x.NewPassword).WithMessage("Potvrda lozinke se ne podudara sa novom lozinkom.");
        }
    }
}
