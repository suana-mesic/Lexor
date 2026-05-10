using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class LeaveRejectValidator:AbstractValidator<LeaveRejectRequest>
    {
        public LeaveRejectValidator()
        {
            RuleFor(x => x.RejectionReason)
                .MaximumLength(1000).WithMessage("Razlog odbijanja zahtjeva ne može imati više od 1000 karaktera.");
        }
    }
}
