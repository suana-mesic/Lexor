using Lexor.Model.Enums;
using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Mapster;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartComponents.LocalEmbeddings;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace Lexor.Services
{
    public class ChatService : IChatService
    {
        private readonly LexorDbContext _dbContext;
        private readonly LocalEmbedder _embedder;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly GroqOptions _groq;
        private readonly IAuthenticatedUserAccessor _userAccessor;

        // How many of the most relevant chunks to feed the model as context.
        private const int TopK = 6;
        public ChatService(LexorDbContext dbContext, LocalEmbedder embedder, IHttpClientFactory httpClientFactory, IOptions<GroqOptions> groqOptions,  IAuthenticatedUserAccessor userAccessor)
        {
            _dbContext = dbContext;
            _embedder = embedder;
            _httpClientFactory = httpClientFactory;
            _groq = groqOptions.Value;
            _userAccessor = userAccessor;
        }
        public async Task<ChatResponse> AskAsync(ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Question))
                throw new BusinessException("Pitanje ne može biti prazno.");

            // 1) Embed the question locally (same model as the chunks -> same vector size).
            var questionVector = _embedder.Embed(request.Question).Values.ToArray();


            // 2) Load chunks of active documents, score each by cosine similarity in memory
            //    (semantic search can't be expressed in SQL Server without vector support;
            //    the corpus is small so this is cheap).

            var chunks = await _dbContext.Set<LegalDocumentChunk>()
                .Where(c => c.EmbeddingJson != null && c.LegalDocument.IsActive)
                .Select(c => new { c.ChunkText, c.EmbeddingJson, DocumentName = c.LegalDocument.Name })
                .ToListAsync();

            if (chunks.Count == 0)
                return new ChatResponse { Answer = "Trenutno nema dostupnih dokumenata za odgovor." };

            var keywords = ExtractKeywords(request.Question);

            var top = chunks
                        .Select(c =>
                        {
                            var vector = JsonSerializer.Deserialize<float[]>(c.EmbeddingJson!)!;
                            // Combine semantic similarity with a lexical boost so questions with a
                            // distinctive term (e.g. "mobing") still surface the chunks that contain it,
                            // even when the small local embedding model misses them on Bosnian text.
                            var score = CosineSimilarity(questionVector, vector) + 0.3f * KeywordScore(c.ChunkText, keywords);
                            return new { c.ChunkText, c.DocumentName, Score = score };
                        })
                        .OrderByDescending(c => c.Score)
                        .Take(TopK)
                        .ToList();

            // 3) Build the context block and ask Groq.
            var context = string.Join("\n\n---\n\n", top.Select(t => t.ChunkText));
            var answer = await AskGroqAsync(request.Question, context);
            var sources = top.Select(t => t.DocumentName).Distinct().ToList();

            await SaveToHistoryAsync(request.Question, answer, sources);
            return new ChatResponse { Answer = answer, Sources = sources };
        }

        private static float KeywordScore(string chunkText, List<string> keywords)
        {
            if (keywords.Count == 0) return 0f;
            var lower = chunkText.ToLowerInvariant();
            // Match on a 6-char stem so Bosnian inflections still hit (e.g. "mobinga" -> "mobing").
            var matches = keywords.Count(k => lower.Contains(k.Length > 6 ? k.Substring(0, 6) : k));
            return (float)matches / keywords.Count;
        }

        private static List<string> ExtractKeywords(string question)
        {
            return question.ToLowerInvariant()
               .Split(new[] { ' ', ',', '.', '?', '!', ';', ':', '\n', '\r', '\t', '"', '(', ')' },
               StringSplitOptions.RemoveEmptyEntries)
               .Where(w => w.Length > 3)
               .Distinct()
               .ToList();
        }

        private static float CosineSimilarity(float[] a, float[] b)
        {
            if (a.Length != b.Length) return 0f;
            float dot = 0, normA = 0, normB = 0;
            for (var i = 0; i < a.Length; i++)
            {
                dot += a[i] * b[i];
                normA += a[i] * a[i];
                normB += b[i] * b[i];
            }

            return (normA == 0 || normB == 0) ? 0f : dot / (MathF.Sqrt(normA) * MathF.Sqrt(normB));
        }


        private async Task SaveToHistoryAsync(string question, string answer, List<string> sources)
        {
            var employeeId = await GetCurrentEmployeeIdAsync();
            if (employeeId == null) return; // only employees keep a chat history

            // One ongoing conversation per employee, created on the first question.
            var conversation = await _dbContext.Set<ChatConversation>()
                .FirstOrDefaultAsync(c => c.EmployeeId == employeeId);
            if (conversation == null)
            {
                conversation = new ChatConversation
                {
                    EmployeeId = employeeId.Value,
                    Title = "Razgovor sa HR asistentom",
                    CreatedAt = DateTime.UtcNow
                };
                _dbContext.Set<ChatConversation>().Add(conversation);
            }

            var now = DateTime.UtcNow;
            conversation.LastMessageAt = now;
            conversation.Messages.Add(new ChatMessage
            {
                Role = ChatMessageRole.User,
                Content = question,
                Timestamp = now
            });
            conversation.Messages.Add(new ChatMessage
            {
                Role = ChatMessageRole.Assistant,
                Content = answer,
                Citations = sources.Count > 0 ? JsonSerializer.Serialize(sources) : null,
                Timestamp = now
            });

            await _dbContext.SaveChangesAsync();
        }


        private async Task<string> AskGroqAsync(string question, string context)
        {
            var systemPrompt =
             "Ti si asistent za ljudske resurse. Odgovaraj isključivo na osnovu priloženih " +
             "izvoda iz internih dokumenata kompanije. Ako odgovor nije u njima, reci da ne znaš " +
             "i predloži da se obrate HR odjelu. Odgovaraj kratko i jasno, na bosanskom jeziku. " +
             "Piši običnim tekstom bez markdown oznaka — ne koristi **, *, _ ni # za formatiranje.";


            var payload = new
            {
                model = _groq.Model,
                temperature = 0.2,
                messages = new object[]
                {
                    new { role = "system", content = systemPrompt },
                    new { role = "user", content = $"Izvodi iz dokumenata:\n{context}\n\nPitanje: {question}" }
                }
            };

            var client = _httpClientFactory.CreateClient();
            client.BaseAddress = new Uri(_groq.BaseUrl.TrimEnd('/') + "/");
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _groq.ApiKey);

            HttpResponseMessage response;
            try
            {
                response = await client.PostAsJsonAsync("chat/completions", payload);
            }
            catch (Exception)
            {
                throw new BusinessException("Chatbot trenutno nije dostupan. Pokušajte ponovo kasnije.");
            }

            if (!response.IsSuccessStatusCode)
                throw new BusinessException("Chatbot trenutno nije dostupan. Pokušajte ponovo kasnije.");

            using var stream = await response.Content.ReadAsStreamAsync();
            using var doc = await JsonDocument.ParseAsync(stream);
            var content = doc.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString();

            return string.IsNullOrWhiteSpace(content)
                   ? "Nažalost, nije bilo moguće generisati odgovor."
                   : MarkdownText.ToPlainText(content);
        }


        private async Task<int?> GetCurrentEmployeeIdAsync()
        {
            var userId = _userAccessor.GetUserId();
            if (userId == null) return null;
            return await _dbContext.Set<Employee>()
                .Where(e => e.UserId == userId)
                .Select(e => (int?)e.Id)
                .FirstOrDefaultAsync();
        }

        public async Task<PageResult<ChatMessageResponse>> GetHistoryAsync(int page, int pageSize)
        {
            var employeeId = await GetCurrentEmployeeIdAsync();
            if (employeeId == null)
                return new PageResult<ChatMessageResponse> { Items = new(), TotalCount = 0 };

            page = page < 1 ? 1 : page;
            pageSize = Math.Clamp(pageSize, 1, 50); // hard upper limit (spec)

            var query = _dbContext.Set<ChatMessage>()
                .Where(m => m.ChatConversation.EmployeeId == employeeId);

            var totalCount = await query.CountAsync();

            // Newest first: page 1 = most recent messages. The client reverses for display
            // and requests higher pages as the user scrolls up to older messages.
            var rows = await query
                .OrderByDescending(m => m.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new { m.Role, m.Content, m.Citations, m.Timestamp })
                .ToListAsync();

            var items = rows.Select(m => new ChatMessageResponse
            {
                Role = (int)m.Role,
                // Answers are stripped before they are stored, but rows saved before that was
                // added still carry markdown — clean them on the way out too, so an old
                // conversation does not show stray asterisks.
                Content = m.Role == ChatMessageRole.Assistant
                    ? MarkdownText.ToPlainText(m.Content)
                    : m.Content,
                Timestamp = m.Timestamp,
                Sources = string.IsNullOrEmpty(m.Citations)
                    ? new List<string>()
                    : JsonSerializer.Deserialize<List<string>>(m.Citations)!
            }).ToList();

            return new PageResult<ChatMessageResponse> { Items = items, TotalCount = totalCount };
        }
    }
}
