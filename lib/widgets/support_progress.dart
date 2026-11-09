import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../theme/app_theme.dart';

/// Barra de progresso de apoio da comunidade até a meta de 80%.
class SupportProgress extends StatelessWidget {
  final Issue issue;
  const SupportProgress({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final percent = (issue.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: issue.progress,
            minHeight: 6,
            backgroundColor: AppColors.primarySoft,
            color: issue.reachedThreshold ? AppColors.success : AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${issue.likes} de ${issue.activeRegionalUsers} apoios ($percent%)',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
