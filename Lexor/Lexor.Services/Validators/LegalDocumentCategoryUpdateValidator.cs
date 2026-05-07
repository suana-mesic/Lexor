using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentCategoryUpdateValidator : AbstractValidator<LegalDocumentCategoryUpdateRequest>
    {
        public LegalDocumentCategoryUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(150).WithMessage("Naziv kategorije pravnog dokumenta ne može imati više od 150 karaktera.");
        }
    }
}
