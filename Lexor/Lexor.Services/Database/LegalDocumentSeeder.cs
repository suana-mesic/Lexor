using Lexor.Model.Constants;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    /// <summary>
    /// Seeds the legal-document corpus the HR chatbot answers from. The PDF files ship with the
    /// build (see Lexor.Services.csproj) and are read from the output directory, stored as base64
    /// in the database (same shape as an admin upload), then indexed in place so the chatbot has
    /// searchable chunks immediately on a fresh database. Runs once, only when no documents exist.
    /// </summary>
    public static class LegalDocumentSeeder
    {
        // File name (under SeedData/LegalDocuments) -> display name + category it belongs to.
        // All four are laws, so they share the "Zakon" category (the subject lives in the name).
        private static readonly (string File, string Name, string Category)[] Documents =
        {
            ("zakon-o-radu.pdf", "Zakon o radu (prečišćeni tekst)", "Zakon"),
            ("zakon-o-zastiti-na-radu.pdf", "Zakon o zaštiti na radu", "Zakon"),
            ("zakon-o-mio.pdf", "Zakon o penzijskom i invalidskom osiguranju", "Zakon"),
            ("zakon-o-zdravstvenom-osiguranju.pdf", "Zakon o zdravstvenom osiguranju", "Zakon"),
        };

        public static async Task SeedAsync(LexorDbContext db, ILegalDocumentIndexer indexer)
        {
            if (await db.Set<LegalDocument>().AnyAsync())
                return;

            var folder = Path.Combine(AppContext.BaseDirectory, "SeedData", "LegalDocuments");
            if (!Directory.Exists(folder))
                return;

            // The admin who "uploaded" the seeded documents (UploadedByAdminId is a required FK).
            var uploaderId = await db.Set<User>()
                .Where(u => u.UserRoles.Any(ur => ur.Role.Name == RoleNames.Administrator))
                .Select(u => u.Id)
                .FirstOrDefaultAsync();
            if (uploaderId == 0)
                uploaderId = await db.Set<User>().Select(u => u.Id).FirstOrDefaultAsync();
            if (uploaderId == 0)
                return; // no users seeded yet -> nothing sensible to attribute the upload to

            var inserted = new List<int>();
            foreach (var (file, name, category) in Documents)
            {
                var path = Path.Combine(folder, file);
                if (!File.Exists(path))
                    continue;

                var bytes = await File.ReadAllBytesAsync(path);
                var categoryId = await EnsureCategoryAsync(db, category);

                var document = new LegalDocument
                {
                    Name = name,
                    CategoryId = categoryId,
                    FileBase64 = Convert.ToBase64String(bytes),
                    FileSize = bytes.Length,
                    UploadedByAdminId = uploaderId,
                    UploadedAt = DateTime.UtcNow,
                    IsActive = true,
                };
                db.Set<LegalDocument>().Add(document);
                await db.SaveChangesAsync(); // need the generated Id before indexing
                inserted.Add(document.Id);
            }

            // Extract text, chunk and embed each document so the chatbot can search it. Done here
            // directly (rather than via the RabbitMQ pipeline used for live uploads) so a freshly
            // seeded database has a working chatbot without depending on the subscriber being up.
            foreach (var id in inserted)
            {
                try
                {
                    await indexer.IndexAsync(id);
                }
                catch (Exception ex)
                {
                    // A single unreadable PDF must not stop the app from starting; the document
                    // stays in the database and can be re-indexed from the admin panel.
                    Console.Error.WriteLine($"Legal document {id} could not be indexed during seeding: {ex.Message}");
                }
            }
        }

        private static async Task<int> EnsureCategoryAsync(LexorDbContext db, string name)
        {
            var existing = await db.Set<LegalDocumentCategory>()
                .Where(c => c.Name == name)
                .Select(c => c.Id)
                .FirstOrDefaultAsync();
            if (existing != 0)
                return existing;

            var category = new LegalDocumentCategory { Name = name };
            db.Set<LegalDocumentCategory>().Add(category);
            await db.SaveChangesAsync();
            return category.Id;
        }
    }
}
