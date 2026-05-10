using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

namespace Lexor.Services
{
    public class DepartmentService : BaseCRUDService<Department, DepartmentResponse, DepartmentSearchObject, DepartmentInsertRequest, DepartmentUpdateRequest>, IDepartmentService
    {
        public DepartmentService(LexorDbContext dbContext, IMapper mapper, IValidator<DepartmentInsertRequest> insertValidator, IValidator<DepartmentUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            
        }
        protected override IQueryable<Department> ApplyFilters(IQueryable<Department> query, DepartmentSearchObject? search)
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
