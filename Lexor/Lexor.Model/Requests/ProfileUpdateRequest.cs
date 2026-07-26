namespace Lexor.Model.Requests
{
    // Fields an employee is allowed to change about themselves. Deliberately narrow
    // (no department/position/salary) so self-service can't touch HR/org data.
    public class ProfileUpdateRequest
    {
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }
    }
}
