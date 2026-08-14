using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Lexor.WebAPI.Json
{
    /// <summary>
    /// Serializes every DateTime as UTC with a trailing 'Z'. Timestamps are stored via
    /// DateTime.UtcNow, but SQL Server returns them with Kind=Unspecified; without this the API
    /// would emit them with no timezone and clients would read them as local time (wrong hour).
    /// </summary>
    public class UtcDateTimeConverter : JsonConverter<DateTime>
    {
        private const string Format = "yyyy-MM-ddTHH:mm:ss.fffZ";

        public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            => reader.GetDateTime();

        public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
        {
            var utc = value.Kind == DateTimeKind.Local
                ? value.ToUniversalTime()
                : DateTime.SpecifyKind(value, DateTimeKind.Utc);
            writer.WriteStringValue(utc.ToString(Format, CultureInfo.InvariantCulture));
        }
    }

    /// <summary>Same as <see cref="UtcDateTimeConverter"/> for nullable DateTime properties.</summary>
    public class UtcNullableDateTimeConverter : JsonConverter<DateTime?>
    {
        private const string Format = "yyyy-MM-ddTHH:mm:ss.fffZ";

        public override DateTime? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
            => reader.TokenType == JsonTokenType.Null ? null : reader.GetDateTime();

        public override void Write(Utf8JsonWriter writer, DateTime? value, JsonSerializerOptions options)
        {
            if (value is null)
            {
                writer.WriteNullValue();
                return;
            }
            var v = value.Value;
            var utc = v.Kind == DateTimeKind.Local
                ? v.ToUniversalTime()
                : DateTime.SpecifyKind(v, DateTimeKind.Utc);
            writer.WriteStringValue(utc.ToString(Format, CultureInfo.InvariantCulture));
        }
    }
}
