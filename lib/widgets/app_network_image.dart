import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  static final Map<String, Uint8List> _cache = {};

  final String url;
  final double? width;
  final double height;
  final double radius;

  const AppNetworkImage({
    super.key,
    required this.url,
    required this.height,
    this.width,
    this.radius = 12,
  });

  Widget _placeholder(Widget child) => Container(
        width: width,
        height: height,
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: child,
      );

  Widget _fallback() => _placeholder(
        const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
      );

  Uint8List _decode() => _cache.putIfAbsent(
        url,
        () => base64Decode(url.substring(url.indexOf(',') + 1)),
      );

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (url.isEmpty) {
      image = _placeholder(
        const Icon(Icons.photo_outlined, size: 32, color: AppColors.textMuted),
      );
    } else if (url.startsWith('assets/')) {
      image = Image.asset(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    } else if (url.startsWith('data:')) {
      image = Image.memory(
        _decode(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    } else {
      image = Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : _placeholder(const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )),
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}