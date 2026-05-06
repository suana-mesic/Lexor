namespace Lexor.Model.Requests
{
    public class ContractTypeInsertRequest
    {
        public string Name { get; set; } = string.Empty;
        public bool EndDateRequired { get; set; }
    }
}
