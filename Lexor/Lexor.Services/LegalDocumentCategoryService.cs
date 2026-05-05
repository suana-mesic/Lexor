using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class LegalDocumentCategoryService : BaseCRUDService<LegalDocumentCategory, LegalDocumentCategoryResponse, LegalDocumentCategorySearchObject, LegalDocumentCategoryInsertRequest, LegalDocumentCategoryUpdateRequest>, ILegalDocumentCategoryService
    {
        public LegalDocumentCategoryService(LexorDbContext dbContext, IMapper mapper, IValidator<LegalDocumentCategoryInsertRequest> insertValidator, IValidator<LegalDocumentCategoryUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<LegalDocumentCategory> ApplyFilters(IQueryable<LegalDocumentCategory> query, LegalDocumentCategorySearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
                }
            }
            return query;
        }
    }
}
