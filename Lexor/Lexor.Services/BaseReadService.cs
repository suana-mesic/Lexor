using Lexor.Model.Exceptions;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
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
        private const int MaxPageSize = 100;
        private const int DefaultPageSize = 20;

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

            var page = search.Page ?? 1;
            var pageSize = Math.Clamp(search.PageSize ?? DefaultPageSize, 1, MaxPageSize);

            query = query
              .Skip((page - 1) * pageSize)
              .Take(pageSize);

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
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(TEntity), id));

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
