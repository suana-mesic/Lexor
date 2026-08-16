import 'package:json_annotation/json_annotation.dart';

part 'notification_response.g.dart';

@JsonSerializable(createToJson: false)
class NotificationResponse {
  final int id;
  final String title;
  final String body;
  bool isRead; // mutable so we can flip it locally after marking as read
  final DateTime createdAt;

  NotificationResponse({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);
}
