import 'dart:convert';
import 'dart:typed_data';

final Map<String, Uint8List> _imageCache = {};

/// Decodes a base64 image once and caches the bytes, so repeated widget builds reuse
/// the decoded result instead of decoding it on every frame (guideline A.2).
Uint8List cachedImageBytes(String base64Image) =>
    _imageCache.putIfAbsent(base64Image, () => base64Decode(base64Image));
