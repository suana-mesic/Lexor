using Lexor.Model.Exceptions;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Microsoft.EntityFrameworkCore;
using SmartComponents.LocalEmbeddings;
using System.Text;
using System.Text.Json;
using UglyToad.PdfPig;

namespace Lexor.Services
{
    public class LegalDocumentIndexer : ILegalDocumentIndexer
    {
        private readonly LexorDbContext _dbContext;
        private readonly LocalEmbedder _embedder;

        // ~800 chars per chunk with a 100-char overlap, so a sentence split across a
        // boundary still appears (mostly) in one chunk.
        private const int ChunkSize = 800;
        private const int ChunkOverlap = 100;

        public LegalDocumentIndexer(LexorDbContext dbContext, LocalEmbedder embedder)
        {
            _dbContext = dbContext;
            _embedder = embedder;
        }

        public async Task IndexAsync(int documentId)
        {
            var document = await _dbContext.Set<LegalDocument>()
                .Include(d => d.Chunks)
                .FirstOrDefaultAsync(d => d.Id == documentId)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(LegalDocument), documentId));

            // Re-indexing: drop any existing chunks first.
            if (document.Chunks.Count > 0)
                _dbContext.Set<LegalDocumentChunk>().RemoveRange(document.Chunks);

            var text = ExtractText(Convert.FromBase64String(document.FileBase64));
            var chunks = SplitIntoChunks(text);

            var index = 0;
            foreach (var chunkText in chunks)
            {
                var vector = _embedder.Embed(chunkText).Values.ToArray();
                _dbContext.Set<LegalDocumentChunk>().Add(new LegalDocumentChunk
                {
                    LegalDocumentId = documentId,
                    ChunkIndex = index++,
                    ChunkText = chunkText,
                    EmbeddingJson = JsonSerializer.Serialize(vector)
                });
            }
            await _dbContext.SaveChangesAsync();
        }

        private static string ExtractText(byte[] pdfBytes)
        {
            using var pdf = PdfDocument.Open(pdfBytes);
            var sb = new StringBuilder();
            foreach (var page in pdf.GetPages())
                sb.AppendLine(page.Text);
            return sb.ToString();
        }

        private static List<string> SplitIntoChunks(string text)
        {
            var normalized = string.Join(' ', text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
            var chunks = new List<string>();
            if (normalized.Length == 0)
                return chunks;

            var start = 0;
            while (start < normalized.Length)
            {
                var length = Math.Min(ChunkSize, normalized.Length - start);
                chunks.Add(normalized.Substring(start, length));
                if (start + length >= normalized.Length)
                    break;
                start += ChunkSize - ChunkOverlap;
            }

            return chunks;
        }
    }
}
