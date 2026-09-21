import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utilidad para extraer y decodificar bytes PNG/JPEG de Data URIs o Strings base64
Uint8List? decodeDataUri(String? uri) {
  if (uri == null || uri.isEmpty) return null;
  try {
    if (uri.startsWith('data:image')) {
      final comma = uri.indexOf(',');
      final b64 = comma != -1 ? uri.substring(comma + 1) : uri;
      return base64Decode(b64.replaceAll(RegExp(r'\s+'), ''));
    } else {
      // Intentar decodificar directamente si es base64 puro
      return base64Decode(uri.replaceAll(RegExp(r'\s+'), ''));
    }
  } catch (e) {
    debugPrint('Error al decodificar Data URI: $e');
    return null;
  }
}
