using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Lexor.Model.Exceptions;
using EasyNetQ;
using Lexor.Model;
using System.Security.Cryptography;

namespace Lexor.Services.Access
{
    public class AccessManager : IAccessManager
    {
        private readonly LexorDbContext _dbContext;
        private readonly ITokenService _tokenService;
        private readonly ICryptoService _cryptoService;
        private readonly JwtTokenOptions _jwtOptions;
        private readonly IValidator<LoginRequest> _validator;
        private readonly IValidator<ActivateAccountRequest> _activateValidator;
        private readonly IBus _bus;
        private readonly IValidator<ForgotPasswordRequest> _forgotPasswordValidator;
        private readonly IValidator<ResetPasswordRequest> _resetPasswordValidator;

        private const int MaxResetAttempts = 5;
        public AccessManager(LexorDbContext dbContext, ITokenService tokenService, ICryptoService cryptoService, IOptions<JwtTokenOptions> jwtOptions, IValidator<LoginRequest> validator, IValidator<ActivateAccountRequest> activateValidator, IBus bus, IValidator<ForgotPasswordRequest> forgotPasswordValidator, IValidator<ResetPasswordRequest> resetPasswordValidator)
        {
            _dbContext = dbContext;
            _tokenService = tokenService;
            _cryptoService = cryptoService;
            _jwtOptions = jwtOptions.Value;
            _validator = validator;
            _activateValidator = activateValidator;
            _bus = bus;
            _forgotPasswordValidator = forgotPasswordValidator;
            _resetPasswordValidator = resetPasswordValidator;
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
        public async Task Activate(ActivateAccountRequest request)
        {
            var validationResult = await _activateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var user = await _dbContext.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            // Deliberately vague: don't reveal whether the email exists or the code was wrong.
            if (user == null
                || user.IsCodeActivated
                || string.IsNullOrEmpty(user.InvitationCode)
                || !string.Equals(user.InvitationCode, request.InvitationCode, StringComparison.OrdinalIgnoreCase))
            {
                throw new BusinessException("Neispravan email ili aktivacijski kod, ili je nalog već aktiviran.");
            }
            var salt = _cryptoService.GenerateSalt();
            user.PasswordSalt = salt;
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, salt);
            user.IsCodeActivated = true;
            user.InvitationCode = null;

            await _dbContext.SaveChangesAsync();
        }

        public async Task ForgotPassword(ForgotPasswordRequest request)
        {
            var validationResult = await _forgotPasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var user = await _dbContext.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            // Only send a code to an existing, activated account. We deliberately do NOT
            // reveal whether the email exists (no error either way) to avoid enumeration.
            if (user == null || !user.IsCodeActivated)
                return;

            var code = RandomNumberGenerator.GetInt32(100000, 1000000).ToString(); // 6-digit
            var salt = _cryptoService.GenerateSalt();
            user.PasswordResetCodeSalt = salt;
            user.PasswordResetCodeHash = _cryptoService.GenerateHash(code, salt);
            user.PasswordResetExpiresAt = DateTime.UtcNow.AddMinutes(30);
            user.PasswordResetAttempts = 0;

            await _dbContext.SaveChangesAsync();

            await _bus.PubSub.PublishAsync(new PasswordResetRequested
            {
                Email = user.Email,
                FullName = $"{user.FirstName} {user.LastName}",
                Code = code
            });
        }
        public async Task ResetPassword(ResetPasswordRequest request)
        {
            var validationResult = await _resetPasswordValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var user = await _dbContext.Set<User>()
                .FirstOrDefaultAsync(u => u.Email == request.Email);

            // No active/valid reset code → generic error.
            if (user == null
                || string.IsNullOrEmpty(user.PasswordResetCodeHash)
                || user.PasswordResetExpiresAt == null
                || user.PasswordResetExpiresAt < DateTime.UtcNow)
            {
                throw new BusinessException("Neispravan ili istekao kod za resetovanje lozinke.");
            }

            // Wrong code → count the attempt; after too many, invalidate the code (brute-force guard).
            if (!_cryptoService.Verify(user.PasswordResetCodeHash, user.PasswordResetCodeSalt!, request.Code))
            {
                user.PasswordResetAttempts++;
                if (user.PasswordResetAttempts >= MaxResetAttempts)
                {
                    user.PasswordResetCodeHash = null;
                    user.PasswordResetCodeSalt = null;
                    user.PasswordResetExpiresAt = null;
                    user.PasswordResetAttempts = 0;
                    await _dbContext.SaveChangesAsync();
                    throw new BusinessException("Previše pogrešnih pokušaja. Zatražite novi kod.");
                }
                await _dbContext.SaveChangesAsync();
                throw new BusinessException("Neispravan ili istekao kod za resetovanje lozinke.");
            }

            // Correct code → set the new password and clean up.
            var salt = _cryptoService.GenerateSalt();
            user.PasswordSalt = salt;
            user.PasswordHash = _cryptoService.GenerateHash(request.NewPassword, salt);

            user.PasswordResetCodeHash = null;
            user.PasswordResetCodeSalt = null;
            user.PasswordResetExpiresAt = null;
            user.PasswordResetAttempts = 0;

            var now = DateTime.UtcNow;
            var activeTokens = await _dbContext.Set<RefreshToken>()
                .Where(rt => rt.UserId == user.Id && rt.RevokedAt == null)
                .ToListAsync();
            foreach (var token in activeTokens)
                token.RevokedAt = now;

            await _dbContext.SaveChangesAsync();
        }
    }
}
