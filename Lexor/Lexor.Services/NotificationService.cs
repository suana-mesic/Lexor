using Lexor.Model.Exceptions;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class NotificationService : BaseReadService<Notification, NotificationResponse, NotificationSearchObject>, INotificationService
    {
        private readonly IAuthenticatedUserAccessor _userAccessor;
        public NotificationService(LexorDbContext dbContext, IMapper mapper, IAuthenticatedUserAccessor userAccessor)
           : base(dbContext, mapper)
        {
            _userAccessor = userAccessor;
        }

        protected override IQueryable<Notification> ApplyFilters(IQueryable<Notification> query, NotificationSearchObject? search)
        {
            var currentUserId = _userAccessor.GetUserId();
            query = query.Where(n => n.Employee.UserId == currentUserId);

            if (search?.IsRead.HasValue == true)
                query.Where(n => n.IsRead == search.IsRead);
            return query;
        }
        public async Task<int> GetUnreadCountAsync()
        {
            var currentUserId = _userAccessor.GetUserId();
            return await _dbContext.Set<Notification>().CountAsync(n => !n.IsRead && n.Employee.UserId == currentUserId);
        }
        public async Task<NotificationResponse> MarkAsReadAsync(int id)
        {
            var currentUserId = _userAccessor.GetUserId();

            var entity = await _dbContext.Set<Notification>()
                    .FirstOrDefaultAsync(n => n.Id == id && n.Employee.UserId == currentUserId)
                    ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Notification), id));

            if (!entity.IsRead)
            {
                entity.IsRead = true;
                await _dbContext.SaveChangesAsync();
            }
            return _mapper.Map<NotificationResponse>(entity);
        }
        public async Task MarkAllAsReadAsync()
        {
            var currentUserId = _userAccessor.GetUserId();
            await _dbContext.Set<Notification>()
                .Where(n => n.Employee.UserId == currentUserId && !n.IsRead)
                .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        }
    }
}
