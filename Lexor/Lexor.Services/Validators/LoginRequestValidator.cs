using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LoginRequestValidator : AbstractValidator<LoginRequest>
    {
        public LoginRequestValidator()
        {
            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required")
                .MaximumLength(100).WithMessage("Password cannot exceed 100 characters.");
            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Username is required")
                .MaximumLength(100).WithMessage("Username cannot exceed 100 characters.");
        }
    }
}
