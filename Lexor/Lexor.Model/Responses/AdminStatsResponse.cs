namespace Lexor.Model.Responses
{
    public class AdminStatsResponse
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int InactiveUsers { get; set; }
        public int NotActivatedUsers { get; set; }
        public List<RoleUserCount> UsersPerRole { get; set; } = new();

        // System configuration (reference data) counts.
        public int Departments { get; set; }
        public int Positions { get; set; }
        public int Cities { get; set; }
        public int ContractTypes { get; set; }
        public int LeaveTypes { get; set; }

        // Content / assets.
        public int LegalDocuments { get; set; }
        public int ActiveRfidCards { get; set; }

        // Contracts (status derived from dates — there is no IsActive column).
        public int ActiveContracts { get; set; }
        public int ExpiredContracts { get; set; }
        public int ExpiringSoonContracts { get; set; }
    }

    public class RoleUserCount
    {
        public string RoleName { get; set; } = string.Empty;
        public int Count { get; set; }
    }
}
