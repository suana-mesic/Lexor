class NewsItem {
  final int id;
  final String title;
  final String content;
  final String? imageBase64;
  final DateTime publishedAt;

  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageBase64,
    required this.publishedAt,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
    id: json['id'] as int,
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    imageBase64: json['imageBase64'] as String?,
    publishedAt: _asUtc(json['publishedAt'] as String),
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
