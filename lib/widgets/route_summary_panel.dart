import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/request_state.dart';
import '../models/route_result.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'route_issue_tile.dart';
import 'status_badge.dart';

class RouteSummaryPanel extends StatelessWidget {
  final RequestState state;
  final List<RouteOption> options;
  final int selectedIndex;
  final int bestIndex;
  final String? hint;
  final Map<String, int> categoryCounts;
  final bool showIssues;
  final String errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<Issue> onOpenIssue;
  final ValueChanged<int> onSelectOption;

  const RouteSummaryPanel({
    super.key,
    required this.state,
    required this.options,
    required this.selectedIndex,
    required this.bestIndex,
    required this.hint,
    required this.categoryCounts,
    required this.showIssues,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenIssue,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case RequestState.initial:
        return const SizedBox.shrink();
      case RequestState.loading:
        return const AppCard(
          child: Row(
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Buscando rota...'),
            ],
          ),
        );
      case RequestState.error:
        return AppCard(
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage, style: const TextStyle(fontSize: 13))),
              TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        );
      default:
        return _buildSuccess();
    }
  }

  Widget _buildSuccess() {
    if (options.isEmpty) return const SizedBox.shrink();
    final current = options[selectedIndex];
    final issues = current.issues;
    final hasAlternatives = options.length > 1;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAlternatives) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var i = 0; i < options.length; i++)
                  ChoiceChip(
                    avatar: i == bestIndex ? const Icon(Icons.accessible_forward, size: 16) : null,
                    label: Text(
                      'Rota ${i + 1} • ${options[i].route.durationLabel} • ${options[i].issues.length} ocorr.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: i == selectedIndex,
                    selectedColor: AppColors.primarySoft,
                    onSelected: (_) => onSelectOption(i),
                  ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${current.route.distanceLabel} • ${current.route.durationLabel}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              if (hasAlternatives && selectedIndex == bestIndex) ...[
                const SizedBox(width: 8),
                const StatusBadge(
                  label: 'Mais acessível',
                  icon: Icons.accessible_forward,
                  color: AppColors.success,
                  background: AppColors.successSoft,
                ),
              ],
            ],
          ),
          if (showIssues) ...[
            const SizedBox(height: 10),
            if (issues.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nenhuma ocorrência reportada neste trajeto.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                issues.length == 1
                    ? '1 ocorrência encontrada no trajeto'
                    : '${issues.length} ocorrências encontradas no trajeto',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: categoryCounts.entries
                    .map((e) => StatusBadge(label: '${e.key}: ${e.value}'))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: hasAlternatives ? 120 : 170),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => RouteIssueTile(
                    item: issues[index],
                    onTap: () => onOpenIssue(issues[index].issue),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}