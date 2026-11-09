import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_network_image.dart';
import '../widgets/status_badge.dart';
import '../widgets/support_progress.dart';

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

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
  }

  Future<void> _toggleSupport() async {
    setState(() => _saving = true);
    final updated = await IssueRepository.instance.toggleSupport(_issue);
    if (!mounted) return;

    setState(() {
      _issue = updated;
      _saving = false;
    });
    widget.onChanged?.call(updated);

    final message = !updated.supportedByMe
        ? 'Apoio removido.'
        : updated.reachedThreshold
            ? 'Meta de 80% atingida! Solicitação formal gerada.'
            : 'Obrigado pelo seu apoio!';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    children: [
                      StatusBadge(label: _issue.category),
                      StatusBadge(
                        label: _issue.status,
                        icon: _issue.reachedThreshold ? Icons.gavel : Icons.hourglass_bottom,
                        color: _issue.reachedThreshold ? AppColors.success : AppColors.textMuted,
                        background: _issue.reachedThreshold ? AppColors.successSoft : AppColors.border,
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
                  if (_issue.reachedThreshold) ...[
                    const SizedBox(height: 12),
                    const AppCard(
                      color: AppColors.successSoft,
                      child: Row(
                        children: [
                          Icon(Icons.gavel, color: AppColors.success),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Meta atingida: o ofício foi enviado à prefeitura.'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}