using FluentValidation;
using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    // Self-service account for the currently authenticated user (admin or employee),
    // operating on the User entity only (no employee/org fields).
    public class AccountService : IAccountService
    {
        private readonly LexorDbContext _dbContext;
        private readonly IAuthenticatedUserAccessor _userAccessor;
        private readonly IValidator<AccountUpdateRequest> _validator;

        public AccountService(LexorDbContext dbContext, IAuthenticatedUserAccessor userAccessor,
                              IValidator<AccountUpdateRequest> validator)
        {
            _dbContext = dbContext;
            _userAccessor = userAccessor;
            _validator = validator;
        }

        public async Task<AccountResponse> GetCurrentAsync()
        {
            var user = await LoadCurrentUserAsync();
            return Map(user);
        }

        public async Task<AccountResponse> UpdateAsync(AccountUpdateRequest request)
        {
            await _validator.ValidateAndThrowAsync(request);

            var user = await LoadCurrentUserAsync();

            if (request.Username != null && request.Username != user.Username)
            {
                var taken = await _dbContext.Users
                    .AnyAsync(u => u.Username == request.Username && u.Id != user.Id);
                if (taken)
                    throw new BusinessException("Korisničko ime je već zauzeto.");
                user.Username = request.Username;
            }
            if (request.Email != null) user.Email = request.Email;
            if (request.PhoneNumber != null) user.PhoneNumber = request.PhoneNumber;
            if (request.ProfileImageBase64 != null)
                user.ProfileImageBase64 = request.ProfileImageBase64;

            await _dbContext.SaveChangesAsync();
            return Map(user);
        }

        private async Task<User> LoadCurrentUserAsync()
        {
            var userId = _userAccessor.GetUserId()
                ?? throw new BusinessException("Korisnik nije autentificiran.");

            return await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId)
                ?? throw new NotFoundException("Korisnik nije pronađen.");
        }

        private static AccountResponse Map(User user) => new()
        {
            Id = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Username = user.Username,
            Email = user.Email,
            PhoneNumber = user.PhoneNumber,
            ProfileImageBase64 = user.ProfileImageBase64
        };
    }
}
