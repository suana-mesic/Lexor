namespace Lexor.Model.SearchObjects
{
    public class ContractSearchObject : BaseSearchObject
    {
        public int? EmployeeId { get; set; }
        public int? ContractTypeId { get; set; }
        public bool? OnlyActive { get; set; }
    }
}
