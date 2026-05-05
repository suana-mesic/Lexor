using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest> : 
        BaseReadService<TEntity, TResponse, TSearch>,
        IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
        where TEntity : class
        where TSearch : BaseSearchObject
    {
        protected readonly IValidator<TInsertRequest> _insertValidator;
        protected readonly IValidator<TUpdateRequest> _updateValidator;

        protected BaseCRUDService(LexorDbContext dbContext, IMapper mapper, IValidator<TInsertRequest> insertValidator, IValidator<TUpdateRequest> updateValidator) : base(dbContext, mapper)
        {
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }

        protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        {
            var entity = _mapper.Map<TEntity>(request ?? throw new ArgumentNullException(nameof(request)));
            return entity;
        }

        protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
        {
            _mapper.Map(request, entity);
        }
        public virtual async Task<TResponse> InsertAsync(TInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);

            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e =>_mapper.Map<ValidationFailure>(e));
                throw new ValidationException(errors);
            }

            var entity = MapInsertRequestToEntity(request);

            // Set CreatedAt if exists
            var createdAtProperty = entity.GetType().GetProperty("CreatedAt");
            if (createdAtProperty?.CanWrite == true)
            {
                createdAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            _dbContext.Set<TEntity>().Add(entity);
            await _dbContext.SaveChangesAsync();

            var newId = (int) entity.GetType().GetProperty("Id").GetValue(entity);
            return await GetByIdAsync(newId);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                var error = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new ValidationException(error);
            }

            var entity = await _dbContext.Set<TEntity>().FindAsync(id);

            if(entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

            MapUpdateRequestToEntity(request, entity);

            var updatedAtProperty = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAtProperty?.CanWrite == true)
            {
                updatedAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        public virtual async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found");

            _dbContext.Set<TEntity>().Remove(entity);
            await _dbContext.SaveChangesAsync();
        }
    }
}
