using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractUpdateValidator : AbstractValidator<ContractUpdateRequest>
    {
        public ContractUpdateValidator()
        {
            RuleFor(x => x.EndDate)
                .GreaterThan(x => x.StartDate).WithMessage("End date must be after start date")
                .When(x => x.EndDate.HasValue && x.StartDate.HasValue);
        }
    }
}
