using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class CountryService : BaseCRUDService<Country, CountryResponse, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>, ICountryService
    {
        public CountryService(LexorDbContext dbContext, IMapper mapper, IValidator<CountryInsertRequest> insertValidator, IValidator<CountryUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
        {
            
        }
        protected override IQueryable<Country> ApplyFilters(IQueryable<Country> query, CountrySearchObject? search)
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
