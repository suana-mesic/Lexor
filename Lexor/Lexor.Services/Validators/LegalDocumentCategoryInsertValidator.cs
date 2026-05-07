using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentCategoryInsertValidator : AbstractValidator<LegalDocumentCategoryInsertRequest>
    {
        public LegalDocumentCategoryInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv kategorije pravnog dokumenta je obavezan.")
                .MaximumLength(150).WithMessage("Naziv kategorije pravnog dokumenta ne može imati više od 150 karaktera.");
        }
    }
}
