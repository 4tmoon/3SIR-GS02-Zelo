import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/request_state.dart';
import '../models/route_result.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'route_issue_tile.dart';
import 'status_badge.dart';

/// Resumo da rota: distância, tempo e ocorrências encontradas no trajeto.
/// Fica em branco enquanto nenhuma rota foi pedida.
class RouteSummaryPanel extends StatelessWidget {
  final RequestState state;
  final RouteResult? route;
  final List<RouteIssue> issues;
  final Map<String, int> categoryCounts;
  final bool showIssues;
  final String errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<Issue> onOpenIssue;

  const RouteSummaryPanel({
    super.key,
    required this.state,
    required this.route,
    required this.issues,
    required this.categoryCounts,
    required this.showIssues,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenIssue,
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
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
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
              Expanded(
                  child:
                      Text(errorMessage, style: const TextStyle(fontSize: 13))),
              TextButton(
                  onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        );
      case RequestState.success:
        return _buildSuccess();
    }
  }

  Widget _buildSuccess() {
    final current = route;
    if (current == null) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${current.distanceLabel} • ${current.durationLabel}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (showIssues) ...[
            const SizedBox(height: 10),
            if (issues.isEmpty)
              const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.success),
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                constraints: const BoxConstraints(maxHeight: 190),
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
