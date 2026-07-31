namespace Lexor.Services
{
    public interface IAuthenticatedUserAccessor
    {
        int? GetUserId();
        bool IsInRole(string role);

        bool IsBackOffice();
    }
}
