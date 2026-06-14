using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace Lexor.Services.Access
{
    public class AccessManager : IAccessManager
    {
        private readonly LexorDbContext _dbContext;
        private readonly ITokenService _tokenService;
        private readonly ICryptoService _cryptoService;
        private readonly JwtTokenOptions _jwtOptions;
        private readonly IValidator<LoginRequest> _validator;

        public AccessManager(LexorDbContext dbContext, ITokenService tokenService, ICryptoService cryptoService, IOptions<JwtTokenOptions> jwtOptions, IValidator<LoginRequest> validator)
        {
            _dbContext = dbContext;
            _tokenService = tokenService;
            _cryptoService = cryptoService;
            _jwtOptions = jwtOptions.Value;
            _validator = validator;
        }

        public async Task<LoginResponse?> Login(LoginRequest request)
        {
            var validationResult = await _validator.ValidateAsync(request);

            if (validationResult.IsValid == false)
            {
                throw new ValidationException(validationResult.Errors);
            }

            var user = await _dbContext.Set<User>()
                .Include(u => u.UserRoles)
                    .ThenInclude(u => u.Role)
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null || !_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password) || !user.IsActive)
                return null;

            user.LastLoginAt = DateTime.UtcNow;

            var accessToken = _tokenService.GenerateAccessToken(user);
            var refreshToken = _tokenService.GenerateRefreshToken();

            var refreshTokenEntity = new RefreshToken
            {
                UserId = user.Id,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(_jwtOptions.RefreshTokenDurationInDays)
            };

            _dbContext.Set<RefreshToken>().Add(refreshTokenEntity);
            await _dbContext.SaveChangesAsync();

            return new LoginResponse
            {
                UserId = user.Id,
                AccessToken = accessToken,
                RefreshToken = refreshToken
            };
        }

        public async Task Logout(RefreshTokenRequest request)
        {
            var token = await _dbContext.Set<RefreshToken>()
               .FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken);

            if (token != null && token.RevokedAt == null)
            {
                token.RevokedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync();
            }
        }

        public async Task<LoginResponse?> Refresh(RefreshTokenRequest request)
        {
            var existingRefreshToken = await _dbContext.Set<RefreshToken>()
               .Include(rt => rt.User)
                   .ThenInclude(u => u.UserRoles)
                       .ThenInclude(u => u.Role)
               .FirstOrDefaultAsync(rt => rt.Token == request.RefreshToken);

            if (existingRefreshToken == null ||
                existingRefreshToken.RevokedAt != null ||
                existingRefreshToken.ExpiresAt <= DateTime.UtcNow)
                return null;

            existingRefreshToken.RevokedAt = DateTime.UtcNow;

            var newAccessToken = _tokenService.GenerateAccessToken(existingRefreshToken.User);
            var newRefreshToken = _tokenService.GenerateRefreshToken();

            var refreshTokenEntity = new RefreshToken
            {
                UserId = existingRefreshToken.UserId,
                Token = newRefreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(_jwtOptions.RefreshTokenDurationInDays)
            };

            _dbContext.RefreshTokens.Add(refreshTokenEntity);
            await _dbContext.SaveChangesAsync();
            return new LoginResponse
            {
                UserId = existingRefreshToken.UserId,
                AccessToken = newAccessToken,
                RefreshToken = newRefreshToken
            };
        }
    }
}
