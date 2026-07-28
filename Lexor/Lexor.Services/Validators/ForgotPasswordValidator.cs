using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ForgotPasswordValidator : AbstractValidator<ForgotPasswordRequest>
    {
        public ForgotPasswordValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Unesite ispravan email.");
        }
    }
}