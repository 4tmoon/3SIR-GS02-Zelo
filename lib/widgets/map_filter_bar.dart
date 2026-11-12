import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../theme/app_theme.dart';
import 'category_style.dart';

class MapFilterBar extends StatelessWidget {
  final int filterCount;
  final VoidCallback onFilters;
  final VoidCallback onLegend;

  const MapFilterBar({
    super.key,
    required this.filterCount,
    required this.onFilters,
    required this.onLegend,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: onFilters,
            style: OutlinedButton.styleFrom(
              backgroundColor: filterCount > 0 ? AppColors.primarySoft : Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(filterCount > 0 ? 'Filtros ($filterCount)' : 'Filtros'),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              tooltip: 'Legenda',
              icon: const Icon(Icons.info_outline),
              onPressed: onLegend,
            ),
          ),
        ],
      ),
    );
  }
}

void showMapLegend(BuildContext context) {
  Widget dot(Color color, IconData icon) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: Colors.white),
      );

  Widget row(Widget leading, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 36, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Legenda do mapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Ícone = categoria', style: TextStyle(color: AppColors.textMuted)),
            for (final category in IssueCategory.all)
              row(dot(AppColors.primary, CategoryStyle.icon(category)), category),
            const SizedBox(height: 6),
            const Text('Cor = andamento', style: TextStyle(color: AppColors.textMuted)),
            row(dot(AppColors.warning, Icons.place), 'Coletando apoio'),
            row(dot(AppColors.success, Icons.place), 'Ofício gerado'),
            const SizedBox(height: 6),
            const Text('Rota', style: TextStyle(color: AppColors.textMuted)),
            row(
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0x33EF6C00),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warning),
                ),
              ),
              'Círculo de 150 m: ocorrência considerada "na rota"',
            ),
            row(
              Container(width: 28, height: 5, color: AppColors.primary),
              'Rota escolhida (as outras aparecem mais claras)',
            ),
          ],
        ),
      ),
    ),
  );
}