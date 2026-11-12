import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../theme/app_theme.dart';

/// Ícones e cores usados para categorias, andamento e gravidade.
class CategoryStyle {
  static IconData icon(String category) {
    if (category == IssueCategory.accessibility) return Icons.accessible;
    if (category == IssueCategory.safety) return Icons.shield;
    if (category == IssueCategory.infrastructure) return Icons.construction;
    return Icons.place;
  }

  /// Verde quando o ofício já foi gerado; laranja enquanto ainda coleta apoio.
  static Color stateColor(Issue issue) => issue.hasNotice ? AppColors.success : AppColors.warning;
}

class SeverityStyle {
  static Color color(String severity) {
    if (severity == IssueSeverity.high) return AppColors.danger;
    if (severity == IssueSeverity.low) return AppColors.success;
    return AppColors.warning;
  }

  static Color soft(String severity) {
    if (severity == IssueSeverity.high) return AppColors.dangerSoft;
    if (severity == IssueSeverity.low) return AppColors.successSoft;
    return AppColors.warningSoft;
  }
}