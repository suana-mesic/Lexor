using System.Security.Cryptography;
using System.Text;

namespace Lexor.Services.Helpers
{
    public class CryptoService : ICryptoService
    {
        private const int Pbkdf2Iterations = 10000;
        private const int HashSizeBytes = 32;     // SHA-256 = 32 bytes
        private const int SaltSizeBytes = 16;
        public string GenerateHash(string password, string salt)
        {
            //Creates a PBKDF2 (Password-Based Key Derivation Function 2) instance — RFC 2898. It takes the password and salt, then runs HMAC-SHA256 10,000 times in a loop.
            var pbkdf2 = new Rfc2898DeriveBytes(password, Encoding.UTF8.GetBytes(salt), Pbkdf2Iterations, HashAlgorithmName.SHA256);
            byte[] hash = pbkdf2.GetBytes(HashSizeBytes); // SHA-256 produces 32 bytes
            return Convert.ToBase64String(hash);
        }

        public string GenerateSalt()
        {
            // Creates a cryptographically secure random number generator
            byte[] saltBytes = RandomNumberGenerator.GetBytes(SaltSizeBytes);
            return Convert.ToBase64String(saltBytes); // encodes the binary salt as Base64 for DB storage.
        }

        public bool Verify(string dbHash, string salt, string password)
        {
            // Hashes the candidate password with the stored salt, then compares the two hash strings. 
            // Password is entered correctly if they're equal.
            var generatedHash = GenerateHash(password, salt);

            //prevents attacker to count the time needed for the comparison
            return CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(dbHash), Encoding.UTF8.GetBytes(generatedHash));
        }
    }
}
