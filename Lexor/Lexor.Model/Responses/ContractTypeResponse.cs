namespace Lexor.Model.Responses
{
    public class ContractTypeResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool EndDateRequired { get; set; }
    }
}
