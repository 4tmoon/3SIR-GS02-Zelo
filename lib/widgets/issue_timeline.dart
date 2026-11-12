import 'package:flutter/material.dart';

import '../models/issue_history.dart';
import '../theme/app_theme.dart';

/// Linha do tempo (histórico)
class IssueTimeline extends StatelessWidget {
  final List<HistoryStep> steps;
  final VoidCallback onViewNotice;

  const IssueTimeline({super.key, required this.steps, required this.onViewNotice});

  static IconData _icon(HistoryStep step) {
    if (step.kind == HistoryKind.created) return Icons.add_location_alt;
    if (step.kind == HistoryKind.goalReached) return Icons.groups;
    if (step.kind == HistoryKind.noticeGenerated) return Icons.gavel;
    if (step.status == HistoryStatus.accepted) return Icons.verified;
    if (step.status == HistoryStatus.awaiting) return Icons.hourglass_top;
    return Icons.account_balance;
  }

  static Color _color(HistoryStatus status) {
    if (status == HistoryStatus.done || status == HistoryStatus.accepted) return AppColors.success;
    if (status == HistoryStatus.awaiting) return AppColors.primary;
    return AppColors.textMuted;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _format(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year} às ${_two(d.hour)}:${_two(d.minute)}';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], isLast: i == steps.length - 1, onViewNotice: onViewNotice),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final HistoryStep step;
  final bool isLast;
  final VoidCallback onViewNotice;

  const _TimelineRow({required this.step, required this.isLast, required this.onViewNotice});

  @override
  Widget build(BuildContext context) {
    final color = IssueTimeline._color(step.status);
    final filled = step.status == HistoryStatus.done || step.status == HistoryStatus.accepted;
    final pending = step.status == HistoryStatus.pending;
    final lineColor = step.status == HistoryStatus.done ? AppColors.success : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? color
                        : step.status == HistoryStatus.awaiting
                            ? AppColors.primarySoft
                            : Colors.white,
                    border: Border.all(color: pending ? AppColors.border : color, width: 1.5),
                  ),
                  child: Icon(
                    IssueTimeline._icon(step),
                    size: 20,
                    color: filled ? Colors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(child: Container(width: 2, color: lineColor)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pending ? AppColors.textMuted : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(step.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  if (step.date != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      IssueTimeline._format(step.date!),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    ),
                  ],
                  if (step.kind == HistoryKind.noticeGenerated && step.status == HistoryStatus.done) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onViewNotice,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Ver ofício em PDF'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}