import 'package:flutter/material.dart';

import '../models/route_result.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Campos de partida e chegada, modo de deslocamento e opção de mostrar ocorrências.
class RouteSearchCard extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final TravelMode mode;
  final bool showIssues;
  final bool expanded;
  final bool isLoading;
  final bool hasRoute;
  final ValueChanged<TravelMode> onModeChanged;
  final ValueChanged<bool> onShowIssuesChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final VoidCallback onSwap;
  final VoidCallback onToggleExpanded;

  const RouteSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.mode,
    required this.showIssues,
    required this.expanded,
    required this.isLoading,
    required this.hasRoute,
    required this.onModeChanged,
    required this.onShowIssuesChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onSwap,
    required this.onToggleExpanded,
  });

  InputDecoration _dense(String label, IconData icon) =>
      appInputDecoration(label: label, icon: icon).copyWith(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    if (!expanded && hasRoute) {
      return AppCard(
        onTap: onToggleExpanded,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${originController.text} → ${destinationController.text}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar rota',
              onPressed: onToggleExpanded,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Limpar rota',
              onPressed: onClear,
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: originController,
                      textInputAction: TextInputAction.next,
                      decoration: _dense('Partida', Icons.trip_origin),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: destinationController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSubmit(),
                      decoration: _dense('Chegada', Icons.flag_outlined),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: 'Inverter partida e chegada',
                onPressed: onSwap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.directions_walk, size: 16),
                label: const Text('A pé'),
                selected: mode == TravelMode.walking,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => onModeChanged(TravelMode.walking),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.directions_car, size: 16),
                label: const Text('Carro'),
                selected: mode == TravelMode.driving,
                selectedColor: AppColors.primarySoft,
                onSelected: (_) => onModeChanged(TravelMode.driving),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                child: Text('Mostrar ocorrências no trajeto',
                    style: TextStyle(fontSize: 13)),
              ),
              Switch(value: showIssues, onChanged: onShowIssuesChanged),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  icon: const Icon(Icons.alt_route, size: 18),
                  label: Text(isLoading ? 'Buscando...' : 'Traçar rota'),
                ),
              ),
              if (hasRoute) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onClear, child: const Text('Limpar')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
