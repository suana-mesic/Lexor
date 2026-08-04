namespace Lexor.Model.Responses
{
    public class AdminStatsResponse
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int InactiveUsers { get; set; }
        public List<RoleUserCount> UsersPerRole { get; set; } = new();
    }

    public class RoleUserCount
    {
        public string RoleName { get; set; } = string.Empty;
        public int Count { get; set; }
    }
}
