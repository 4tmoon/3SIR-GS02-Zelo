import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/issue.dart';
import '../repositories/issue_repository.dart';
import '../services/notice_pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import 'issue_detail_screen.dart';
import 'notice_preview_screen.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final _repository = IssueRepository.instance;
  final _pdfService = NoticePdfService();
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

  void _openPreview(Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoticePreviewScreen(issue: issue)),
    );
  }

  Future<void> _download(Issue issue) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Gerando PDF...'), duration: Duration(seconds: 2)));
    try {
      final bytes = await _pdfService.build(issue);
      await Printing.sharePdf(bytes: bytes, filename: _pdfService.fileName(issue));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Não foi possível gerar o PDF.')));
    }
  }

  Widget _decisionBadge(Issue issue) {
    if (issue.decision == IssueDecision.accepted) {
      return const StatusBadge(
        label: 'Aceita pela prefeitura',
        icon: Icons.verified,
        color: AppColors.success,
        background: Colors.white,
      );
    }
    return const StatusBadge(
      label: 'Aguardando resposta',
      icon: Icons.hourglass_top,
      color: AppColors.textMuted,
      background: Colors.white,
    );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel, color: AppColors.success),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ofício Nº ${_pdfService.noticeNumber(notice)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${notice.address} • ${(notice.progress * 100).round()}% de apoio',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 6),
                              _decisionBadge(notice),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openPreview(notice),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: const Text('Visualizar'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _download(notice),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Baixar PDF'),
                          ),
                        ),
                      ],
                    ),
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