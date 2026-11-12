import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_network_image.dart';
import 'status_badge.dart';
import 'support_progress.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;

  const IssueCard({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AppNetworkImage(url: issue.imageUrl, width: double.infinity, height: 170, radius: 0),
              Positioned(top: 10, left: 10, child: StatusBadge(label: issue.category, background: Colors.white)),
              if (issue.hasNotice)
                const Positioned(
                  top: 10,
                  right: 10,
                  child: StatusBadge(
                    label: 'Oficial',
                    icon: Icons.gavel,
                    color: AppColors.success,
                    background: Colors.white,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        issue.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SupportProgress(issue: issue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}