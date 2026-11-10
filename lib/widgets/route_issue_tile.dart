import 'package:flutter/material.dart';

import '../models/route_result.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_network_image.dart';
import 'status_badge.dart';

/// Linha compacta de uma ocorrência encontrada na rota.
class RouteIssueTile extends StatelessWidget {
  final RouteIssue item;
  final VoidCallback onTap;

  const RouteIssueTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final issue = item.issue;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          AppNetworkImage(
              url: issue.imageUrl, width: 48, height: 48, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(label: issue.category),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'a ${item.distanceMeters.round()} m da rota',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
