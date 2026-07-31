namespace Lexor.Model.Constants
{
    public static class RoleNames
    {
        // Business role names. The value is stored in Role.Name and emitted as the
        // JWT role claim, so [Authorize(Roles = ...)] matches against these strings.
        public const string Administrator = "Administrator";
        public const string HrManager = "HRManager";
        public const string Accounting = "Accounting";
        public const string Employee = "Employee";
    }
}
