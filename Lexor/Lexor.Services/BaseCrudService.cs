using Lexor.Model.Exceptions;
using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Lexor.Services.Helpers;

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
        protected readonly IAuthenticatedUserAccessor _userAccessor;

        protected BaseCRUDService(LexorDbContext dbContext, IMapper mapper, IValidator<TInsertRequest> insertValidator, IValidator<TUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper)
        {
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
            _userAccessor = userAccessor;
        }

        protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        {
            var entity = _mapper.Map<TEntity>(request);
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
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new ValidationException(errors);
            }

            var entity = MapInsertRequestToEntity(request);

            // Set CreatedAt & CreatedByUserId fields if they exist on this entity
            ApplyCreateAuditFields(entity);

            _dbContext.Set<TEntity>().Add(entity);
            await _dbContext.SaveChangesAsync();

            var newId = (int)entity.GetType().GetProperty("Id").GetValue(entity);
            return await GetByIdAsync(newId);
        }

        public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new ValidationException(errors);
            }

            var entity = await _dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(TEntity), id));

            MapUpdateRequestToEntity(request, entity);

            // Set UpdatedAt & UpdatedByUserId fields if they exist on this entity
            ApplyUpdateAuditFields(entity);

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        public virtual async Task DeleteAsync(int id)
        {
            var entity = await _dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(TEntity), id));

            _dbContext.Set<TEntity>().Remove(entity);
            await _dbContext.SaveChangesAsync();
        }

        protected void ApplyCreateAuditFields(object entity)
        {
            var createdAt = entity.GetType().GetProperty("CreatedAt")
               ?? entity.GetType().GetProperty("AssignedAt");
            if (createdAt?.CanWrite == true)
                createdAt.SetValue(entity, DateTime.UtcNow);

            var createdBy = entity.GetType().GetProperty("CreatedByUserId");
            if (createdBy?.CanWrite == true)
                createdBy.SetValue(entity, _userAccessor.GetUserId() ?? 0);
        }

        protected void ApplyUpdateAuditFields(object entity)
        {
            var updatedAt = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAt?.CanWrite == true)
                updatedAt.SetValue(entity, DateTime.UtcNow);

            var updatedBy = entity.GetType().GetProperty("UpdatedByUserId");
            if (updatedBy?.CanWrite == true)
                updatedBy.SetValue(entity, _userAccessor.GetUserId() ?? 0);
        }
    }
}
