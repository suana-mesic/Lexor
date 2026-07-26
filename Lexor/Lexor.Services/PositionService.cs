using Lexor.Model.Exceptions;
using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class PositionService : BaseCRUDService<Position, PositionResponse, PositionSearchObject, PositionInsertRequest, PositionUpdateRequest>, IPositionService
    {
        public PositionService(LexorDbContext dbContext, IMapper mapper, IValidator<PositionInsertRequest> insertValidator, IValidator<PositionUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
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
                if (search.DepartmentId.HasValue)
                {
                    query = query.Where(c => c.DepartmentId == search.DepartmentId);
                }
            }
            return query;
        }

        protected override IQueryable<Position> IncludeRelatedEntities(PositionSearchObject? search, IQueryable<Position> query)
        {
            return query.Include(p => p.Department);
        }

        public override async Task<PositionResponse> InsertAsync(PositionInsertRequest request)
        {
            await EnsureDepartmentExists(request.DepartmentId);
            return await base.InsertAsync(request);
        }

        public override async Task<PositionResponse> UpdateAsync(int id, PositionUpdateRequest request)
        {
            await EnsureDepartmentExists(request.DepartmentId);
            return await base.UpdateAsync(id, request);
        }

        private async Task EnsureDepartmentExists(int departmentId)
        {
            // Leave the "is required" check (departmentId > 0) to the validator so the
            // user gets a friendly message; here we only guard against a non-existent id.
            if (departmentId <= 0) return;

            var exists = await _dbContext.Departments.AnyAsync(d => d.Id == departmentId);
            if (!exists)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Department), departmentId));
        }
    }
}
