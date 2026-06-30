import 'package:json_annotation/json_annotation.dart';

part 'legal_document_response.g.dart';

@JsonSerializable()
class LegalDocumentResponse {
  final int id;
  final String name;
  final String categoryName;
  final DateTime uploadedAt;

  LegalDocumentResponse({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.uploadedAt,
  });

  factory LegalDocumentResponse.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentResponseFromJson(json);
}
