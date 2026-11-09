import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Image.network com indicador de carregamento e imagem de reserva em caso de erro.
class AppNetworkImage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
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
        errorBuilder: (context, error, stack) => _placeholder(
          const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
        ),
      ),
    );
  }
}
