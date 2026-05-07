using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LoginRequestValidator : AbstractValidator<LoginRequest>
    {
        public LoginRequestValidator()
        {
            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Korisničko ime je obavezno.")
                .MaximumLength(100).WithMessage("Korisničko ime ne može imati više od 100 karaktera.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MaximumLength(100).WithMessage("Lozinka ne može imati više od 100 karaktera.");
        }
    }
}
