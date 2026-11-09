import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/state_views.dart';
import 'issue_detail_screen.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _repository = IssueRepository.instance;
  late Future<List<Issue>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.fetchAll();
  }

  void _reload() => setState(() => _future = _repository.fetchAll());

  Future<void> _openDetail(Issue issue) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ofícios públicos')),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) {
            return ErrorView(message: 'Não foi possível carregar os ofícios.', onRetry: _reload);
          }
          final notices = _repository.officialNotices(snapshot.data ?? []);
          if (notices.isEmpty) {
            return const EmptyView(icon: Icons.gavel, message: 'Nenhum ofício gerado ainda.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return AppCard(
                color: AppColors.successSoft,
                onTap: () => _openDetail(notice),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${notice.address} • ${(notice.progress * 100).round()}% de apoio',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
