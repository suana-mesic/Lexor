namespace Lexor.Model.Responses
{
    public class LoginResponse
    {
        public int UserId { get; set; } 
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
