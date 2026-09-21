import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/garabu_theme.dart';

class GarabuImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const GarabuImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) {
      return placeholder ?? const SizedBox();
    }

    // 1. Manejo de Data URI en Base64
    if (raw.contains('base64,') || (!raw.startsWith('http://') && !raw.startsWith('https://') && raw.length > 50)) {
      try {
        final cleanBase64 = raw.contains('base64,')
            ? raw.split('base64,').last.replaceAll(RegExp(r'\s+'), '')
            : raw.replaceAll(RegExp(r'\s+'), '');
        final Uint8List bytes = base64Decode(cleanBase64);

        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } catch (e) {
        // En caso de base64 malformado
        return _buildFallback();
      }
    }

    // 2. Manejo de URLs HTTP / HTTPS (Firebase Storage u otros)
    return Image.network(
      raw,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: GarabuTheme.primaryBrown,
                ),
              ),
            );
      },
    );
  }

  Widget _buildFallback() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: GarabuTheme.warmSand.withValues(alpha: 0.3),
          child: const Center(
            child: Icon(
              Icons.palette_outlined,
              color: GarabuTheme.primaryBrown,
              size: 20,
            ),
          ),
        );
  }
}
