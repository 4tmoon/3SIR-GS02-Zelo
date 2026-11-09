import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_network_image.dart';

/// Área principal do cadastro: tirar ou escolher a foto da ocorrência.
class IssuePhotoPicker extends StatelessWidget {
  final String imageData;
  final bool showError;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const IssuePhotoPicker({
    super.key,
    required this.imageData,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageData.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            color: showError ? const Color(0xFFFDECEC) : AppColors.primarySoft,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Column(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 52,
                  color: showError ? AppColors.danger : AppColors.primary,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Fotografe o problema',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text(
                  'A foto é o ponto de partida da ocorrência',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.photo_camera, size: 18),
                      label: const Text('Tirar foto'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Galeria'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showError)
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Adicione uma foto para publicar a ocorrência.',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNetworkImage(url: imageData, width: double.infinity, height: 220, radius: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Tirar outra'),
            ),
            TextButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Galeria'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remover'),
            ),
          ],
        ),
      ],
    );
  }
}