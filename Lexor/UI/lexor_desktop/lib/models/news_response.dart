class NewsResponse {
  final int id;
  final String title;
  final String content;
  /// Full-size picture. Only the details endpoint returns it; on list responses it is null.
  final String? imageBase64;

  /// Width-bounded copy the list carries instead of the full picture.
  final String? thumbnailBase64;
  final DateTime publishedAt;
  final int? publishedByUserId;

  NewsResponse({
    required this.id,
    required this.title,
    required this.content,
    this.imageBase64,
    this.thumbnailBase64,
    required this.publishedAt,
    this.publishedByUserId,
  });

  /// Whichever picture this instance actually has — the full one when it came from the
  /// details endpoint, otherwise the thumbnail. Null when the announcement has no picture.
  String? get displayImage {
    final full = imageBase64;
    if (full != null && full.isNotEmpty) return full;
    final thumb = thumbnailBase64;
    if (thumb != null && thumb.isNotEmpty) return thumb;
    return null;
  }

  factory NewsResponse.fromJson(Map<String, dynamic> json) => NewsResponse(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    imageBase64: json['imageBase64'] as String?,
    thumbnailBase64: json['thumbnailBase64'] as String?,
    publishedAt: _asUtc(json['publishedAt'] as String),
    publishedByUserId: json['publishedByUserId'] as int?,
  );
}

/// The API returns UTC timestamps without a 'Z' suffix, so DateTime.parse would read them as
/// local time (no shift). Reinterpret the wall-clock value as UTC so `.toLocal()` shifts correctly.
DateTime _asUtc(String s) {
  final d = DateTime.parse(s);
  return d.isUtc
      ? d
      : DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second,
          d.millisecond, d.microsecond);
}
