namespace Lexor.Model.Enums
{
    // Derived from the contract's date range relative to today — never stored in the database.
    public enum ContractStatus
    {
        Active = 1,    // today is within [StartDate, EndDate] (or EndDate is open)
        Expired = 2,   // EndDate has already passed
        Upcoming = 3   // StartDate is still in the future
    }
}
