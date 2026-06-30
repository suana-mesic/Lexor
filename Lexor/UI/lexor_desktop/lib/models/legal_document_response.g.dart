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

Map<String, dynamic> _$LegalDocumentResponseToJson(
  LegalDocumentResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'categoryName': instance.categoryName,
  'uploadedAt': instance.uploadedAt.toIso8601String(),
};
