using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractTypeInsertValidator : AbstractValidator<ContractTypeInsertRequest>
    {
        public ContractTypeInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv tipa ugovora je obavezan.")
                .MaximumLength(100).WithMessage("Naziv tipa ugovora ne može imati više od 100 karaktera.");
        }
    }
}
