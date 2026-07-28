using System.Net;
using System.Net.Http.Json;

namespace Lexor.Tests
{
    public class RateLimitingTests
    {
        [Fact]
        public async Task Login_Returns429_AfterExceedingRateLimit()
        {
            using var factory = new ApiFactory();
            var client = factory.CreateClient();

            Task<HttpResponseMessage> Login() => client.PostAsync(
                "/Access/login",
                JsonContent.Create(new { username = "username@test.com", password = "wrong" }));

            for(int i = 0; i < 10; i++)
            {
                var response = await Login();
                Assert.NotEqual(HttpStatusCode.TooManyRequests, response.StatusCode);
            }

            var limited = await Login();
            Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
        }
    }
}
