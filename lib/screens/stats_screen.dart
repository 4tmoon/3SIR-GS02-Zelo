import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/issue_stats.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/category_style.dart';
import '../widgets/stat_widgets.dart';
import '../widgets/state_views.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<Issue>> _future;

  @override
  void initState() {
    super.initState();
    _future = IssueRepository.instance.fetchAll();
  }

  void _reload() => setState(() => _future = IssueRepository.instance.fetchAll());

  Widget _section(String title, List<Widget> children) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) {
            return ErrorView(message: 'Não foi possível carregar as estatísticas.', onRetry: _reload);
          }
          final stats = IssueStats.fromIssues(snapshot.data ?? []);
          if (stats.total == 0) {
            return const EmptyView(icon: Icons.insights, message: 'Ainda não há ocorrências.');
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.report_problem_outlined,
                        label: 'Ocorrências',
                        value: '${stats.total}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.thumb_up_alt_outlined,
                        label: 'Apoios da comunidade',
                        value: '${stats.totalSupports}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.gavel,
                        label: 'Ofícios gerados',
                        value: '${stats.withNotice}',
                        color: AppColors.warning,
                        background: AppColors.warningSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        icon: Icons.verified,
                        label: 'Aceitas pela prefeitura',
                        value: '${stats.accepted}',
                        color: AppColors.success,
                        background: AppColors.successSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section('Andamento das solicitações', [
                  BarRow(
                    label: 'Registradas',
                    value: stats.total,
                    max: stats.total,
                    icon: Icons.add_location_alt,
                  ),
                  BarRow(
                    label: 'Meta de 80% atingida',
                    value: stats.reached,
                    max: stats.total,
                    icon: Icons.groups,
                  ),
                  BarRow(
                    label: 'Ofício gerado',
                    value: stats.withNotice,
                    max: stats.total,
                    icon: Icons.gavel,
                    color: AppColors.warning,
                  ),
                  BarRow(
                    label: 'Aceitas pela prefeitura',
                    value: stats.accepted,
                    max: stats.total,
                    icon: Icons.verified,
                    color: AppColors.success,
                  ),
                ]),
                const SizedBox(height: 14),
                _section('Por categoria', [
                  for (final category in IssueCategory.all)
                    BarRow(
                      label: category,
                      value: stats.byCategory[category] ?? 0,
                      max: stats.total,
                      icon: CategoryStyle.icon(category),
                    ),
                ]),
                const SizedBox(height: 14),
                _section('Por gravidade', [
                  for (final severity in IssueSeverity.all)
                    BarRow(
                      label: IssueSeverity.label(severity),
                      value: stats.bySeverity[severity] ?? 0,
                      max: stats.total,
                      color: SeverityStyle.color(severity),
                    ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}