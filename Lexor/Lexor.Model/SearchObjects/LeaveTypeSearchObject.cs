namespace Lexor.Model.SearchObjects
{
    public class LeaveTypeSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }

        // null = show all, true = paid only, false = unpaid only
        public bool? OnlyPaid { get; set; }
    }
}
