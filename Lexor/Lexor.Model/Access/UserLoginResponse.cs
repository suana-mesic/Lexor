namespace Lexor.Model.Access
{
    public class UserLoginResponse
    {
        public string Accesstoken { get; set; } = string.Empty;
        public string Refreshtoken { get; set; } = string.Empty;
    }
}
