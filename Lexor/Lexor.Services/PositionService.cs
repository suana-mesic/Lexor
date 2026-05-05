using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class PositionService : BaseCRUDService<Position, PositionResponse, PositionSearchObject, PositionInsertRequest, PositionUpdateRequest>, IPositionService
    {
        public PositionService(LexorDbContext dbContext, IMapper mapper, IValidator<PositionInsertRequest> insertValidator, IValidator<PositionUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
        {
            
        }
        protected override IQueryable<Position> ApplyFilters(IQueryable<Position> query, PositionSearchObject? search)
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

        //protected override IQueryable<Position> IncludeRelatedEntities(PositionSearchObject search, IQueryable<Position> query)
        //{
        //}
    }
}
