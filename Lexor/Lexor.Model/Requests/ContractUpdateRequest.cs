namespace Lexor.Model.Requests
{
    public class ContractUpdateRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public bool? IsActive { get; set; }
    }
}
