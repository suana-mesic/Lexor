// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legal_document_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegalDocumentResponse _$LegalDocumentResponseFromJson(
  Map<String, dynamic> json,
) => LegalDocumentResponse(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  categoryName: json['categoryName'] as String,
  uploadedAt: DateTime.parse(json['uploadedAt'] as String),
);
