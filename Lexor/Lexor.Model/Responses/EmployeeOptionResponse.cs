namespace Lexor.Model.Responses
{
    /// <summary>
    /// Minimal employee projection (id + name) for autocomplete/dropdown pickers. Deliberately
    /// carries no personal data beyond the display name so it can be exposed to back-office roles
    /// that must pick an employee without having access to the full employee record.
    /// </summary>
    public class EmployeeOptionResponse
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
    }
}
