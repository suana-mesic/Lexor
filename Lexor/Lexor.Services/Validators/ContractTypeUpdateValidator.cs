using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractTypeUpdateValidator : AbstractValidator<ContractTypeUpdateRequest>
    {
        public ContractTypeUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Naziv tipa ugovora ne može imati više od 100 karaktera.");
        }
    }
}
