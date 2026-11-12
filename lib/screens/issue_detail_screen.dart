import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../models/issue.dart';
import '../models/issue_history.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_network_image.dart';
import '../widgets/category_style.dart';
import '../widgets/comments_section.dart';
import '../widgets/issue_timeline.dart';
import '../widgets/status_badge.dart';
import '../widgets/support_progress.dart';
import 'notice_preview_screen.dart';

class IssueDetailScreen extends StatefulWidget {
  final Issue issue;
  final ValueChanged<Issue>? onChanged;
  const IssueDetailScreen({super.key, required this.issue, this.onChanged});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  late Issue _issue;
  bool _saving = false;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _loadComments();
  }

  Future<void> _loadComments() async {
    final data = await IssueRepository.instance.fetchComments(_issue.id);
    if (mounted) setState(() => _comments = data);
  }

  Future<void> _addComment(String text) async {
    final comment = await IssueRepository.instance.addComment(_issue.id, text);
    if (!mounted) return;
    setState(() => _comments = [comment, ..._comments]);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleSupport() async {
    setState(() => _saving = true);
    final hadNotice = _issue.hasNotice;
    final updated = await IssueRepository.instance.toggleSupport(_issue);
    if (!mounted) return;

    setState(() {
      _issue = updated;
      _saving = false;
    });
    widget.onChanged?.call(updated);

    if (!updated.supportedByMe) {
      _showMessage('Apoio removido.');
    } else if (!hadNotice && updated.hasNotice) {
      _showMessage('Meta de 80% atingida! O ofício foi gerado.');
    } else {
      _showMessage('Obrigado pelo seu apoio!');
    }
  }

  void _openNotice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoticePreviewScreen(issue: _issue)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accepted = _issue.decision == IssueDecision.accepted;
    final statusColor = _issue.hasNotice ? AppColors.success : AppColors.textMuted;
    final statusBackground = _issue.hasNotice ? AppColors.successSoft : AppColors.border;
    final statusIcon = accepted
        ? Icons.verified
        : (_issue.hasNotice ? Icons.gavel : Icons.hourglass_bottom);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(url: _issue.imageUrl, width: double.infinity, height: 260, radius: 0),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      StatusBadge(label: _issue.category),
                      StatusBadge(
                        label: 'Gravidade ${IssueSeverity.label(_issue.severity).toLowerCase()}',
                        icon: Icons.priority_high,
                        color: SeverityStyle.color(_issue.severity),
                        background: SeverityStyle.soft(_issue.severity),
                      ),
                      StatusBadge(
                        label: _issue.status,
                        icon: statusIcon,
                        color: statusColor,
                        background: statusBackground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_issue.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_issue.address, style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Descrição', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_issue.description, style: textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apoio da comunidade',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        SupportProgress(issue: _issue),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: _issue.supportedByMe
                              ? OutlinedButton.icon(
                                  onPressed: _saving ? null : _toggleSupport,
                                  icon: const Icon(Icons.thumb_up, size: 18),
                                  label: const Text('Apoio registrado (desfazer)'),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _saving ? null : _toggleSupport,
                                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                                  label: const Text('Apoiar esta ocorrência'),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histórico da solicitação',
                          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        IssueTimeline(
                          steps: IssueHistory.build(_issue),
                          onViewNotice: _openNotice,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: CommentsSection(comments: _comments, onSend: _addComment),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}