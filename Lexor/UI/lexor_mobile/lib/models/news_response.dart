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
    publishedAt: DateTime.parse(json['publishedAt'] as String),
  );
}
