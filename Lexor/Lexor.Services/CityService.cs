using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class CityService : BaseCRUDService<City, CityResponse, CitySearchObject, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        public CityService(LexorDbContext dbContext, IMapper mapper, IValidator<CityInsertRequest> insertValidator, IValidator<CityUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            
        }
        protected override IQueryable<City> ApplyFilters(IQueryable<City> query, CitySearchObject? search)
        {
            if (search != null)
            {
                if (!string.IsNullOrWhiteSpace(search.Name))
                {
                    query = query.Where(c => c.Name.ToLower().Contains(search.Name.ToLower()));
                }
                if (search.CountryId.HasValue)
                {
                    query = query.Where(c=>c.CountryId==search.CountryId);
                }
            }
            return query;
        }

        protected override IQueryable<City> IncludeRelatedEntities(CitySearchObject? search, IQueryable<City> query)
        {
            return query.Include(c => c.Country);
        }
    }
}
