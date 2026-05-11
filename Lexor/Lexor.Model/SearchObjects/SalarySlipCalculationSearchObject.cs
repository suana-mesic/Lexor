using Lexor.Model.Enums;

namespace Lexor.Model.SearchObjects
{
    public class SalarySlipCalculationSearchObject : BaseSearchObject
    {
        public int? EmployeeId { get; set; }
        public int? Year { get; set; }
        public int? Month { get; set; }
        public SalarySlipStatus? Status { get; set; }
    }
}
