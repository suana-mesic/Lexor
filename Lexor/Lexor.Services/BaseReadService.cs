using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;

namespace Lexor.Services
{
    public abstract class BaseReadService<TEntity, TResponse, TSearch> : IBaseReadService<TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        protected readonly LexorDbContext _dbContext;
        protected readonly IMapper _mapper;

        protected BaseReadService(LexorDbContext dbContext, IMapper mapper)
        {
            _dbContext = dbContext;
            _mapper = mapper;
        }
        public virtual async Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null)
        {
            // if search is not provided, instantiate an empty TSearch to avoid NRE when accessing its properties
            search ??= Activator.CreateInstance<TSearch>();
            IQueryable<TEntity> query = _dbContext.Set<TEntity>();

            query = IncludeRelatedEntities(search, query);
            query = ApplyFilters(query, search);

            int? totalCount = null;

            if (search.IncludeTotalCount != false)
                totalCount = await query.CountAsync();

            if (!string.IsNullOrWhiteSpace(search.SortBy))
                query = query.OrderBy(search.SortBy);

            if (search.Page.HasValue && search.PageSize.HasValue)
                query = query
                    .Skip((search.Page.Value - 1) * search.PageSize.Value)
                    .Take(search.PageSize.Value);

            var entities = await query.ToListAsync();
            var list = entities.Select(item => _mapper.Map<TResponse>(item)).ToList();

            var pageResult = new PageResult<TResponse>
            {
                Items = list,
                TotalCount = totalCount
            };

            return pageResult;
        }
        public virtual async Task<TResponse> GetByIdAsync(int id)
        {
            IQueryable<TEntity> query = _dbContext.Set<TEntity>(); 
            query = IncludeRelatedEntities(null, query);
            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id);

            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found");

            return _mapper.Map<TResponse>(entity);
        }

        protected abstract IQueryable<TEntity> ApplyFilters(IQueryable<TEntity> query, TSearch? search);
        protected virtual IQueryable<TEntity> IncludeRelatedEntities(TSearch? search, IQueryable<TEntity> query = null)
        {
            // Override in derived classes to include related entities if necessary
            return query;
        }
    }
}
