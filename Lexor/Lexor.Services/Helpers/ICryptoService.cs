namespace Lexor.Services.Helpers
{
    public interface ICryptoService
    {
        string GenerateHash(string password, string salt);
        string GenerateSalt();
        bool Verify(string hash, string salt, string password);
    }
}
