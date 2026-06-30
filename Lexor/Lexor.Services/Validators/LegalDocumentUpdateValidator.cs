using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentUpdateValidator : AbstractValidator<LegalDocumentUpdateRequest>
    {
        public LegalDocumentUpdateValidator()
        {
            // Parcijalni update: pravila se primjenjuju samo na poslana (ne-null) polja.
            When(x => x.Name != null, () =>
            {
                RuleFor(x => x.Name)
                    .NotEmpty().WithMessage("Naziv dokumenta je obavezan.")
                    .MaximumLength(200).WithMessage("Naziv dokumenta ne može imati više od 200 karaktera.");
            });

            When(x => x.CategoryId.HasValue, () =>
            {
                RuleFor(x => x.CategoryId)
                    .GreaterThan(0).WithMessage("Kategorija je obavezna.");
            });
        }
    }
}
