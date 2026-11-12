import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/issue_filter.dart';
import '../theme/app_theme.dart';
import 'category_style.dart';

Future<IssueFilter?> showIssueFilterSheet(BuildContext context, IssueFilter current) {
  return showModalBottomSheet<IssueFilter>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  final IssueFilter initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late IssueFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Filtros', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => setState(() => _draft = const IssueFilter()),
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _label('Categoria (pode marcar mais de uma)'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final category in IssueCategory.all)
                  FilterChip(
                    avatar: Icon(CategoryStyle.icon(category), size: 16),
                    label: Text(category),
                    selected: _draft.categories.contains(category),
                    selectedColor: AppColors.primarySoft,
                    onSelected: (_) => setState(() => _draft = _draft.toggleCategory(category)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Gravidade (pode marcar mais de uma)'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final severity in IssueSeverity.all)
                  FilterChip(
                    label: Text(IssueSeverity.label(severity)),
                    selected: _draft.severities.contains(severity),
                    selectedColor: SeverityStyle.soft(severity),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _draft.severities.contains(severity) ? SeverityStyle.color(severity) : null,
                    ),
                    onSelected: (_) => setState(() => _draft = _draft.toggleSeverity(severity)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Mostrar apenas'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  avatar: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: const Text('Apoiadas por mim'),
                  selected: _draft.onlySupported,
                  selectedColor: AppColors.primarySoft,
                  onSelected: (value) => setState(() => _draft = _draft.copyWith(onlySupported: value)),
                ),
                FilterChip(
                  avatar: const Icon(Icons.gavel, size: 16),
                  label: const Text('Com ofício'),
                  selected: _draft.onlyNotice,
                  selectedColor: AppColors.successSoft,
                  onSelected: (value) => setState(() => _draft = _draft.copyWith(onlyNotice: value)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _draft),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const FilterButton({super.key, required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Filtros',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: count > 0 ? AppColors.primary : AppColors.border),
              ),
              child: const Icon(Icons.tune, color: AppColors.primary),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActiveFilterChips extends StatelessWidget {
  final IssueFilter filter;
  final ValueChanged<IssueFilter> onChanged;

  const ActiveFilterChips({super.key, required this.filter, required this.onChanged});

  Widget _chip(String label, VoidCallback onDeleted) => InputChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onDeleted: onDeleted,
        backgroundColor: AppColors.primarySoft,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 0,
      children: [
        for (final category in filter.categories)
          _chip(category, () => onChanged(filter.toggleCategory(category))),
        for (final severity in filter.severities)
          _chip(
            'Gravidade ${IssueSeverity.label(severity).toLowerCase()}',
            () => onChanged(filter.toggleSeverity(severity)),
          ),
        if (filter.onlySupported)
          _chip('Apoiadas por mim', () => onChanged(filter.copyWith(onlySupported: false))),
        if (filter.onlyNotice)
          _chip('Com ofício', () => onChanged(filter.copyWith(onlyNotice: false))),
      ],
    );
  }
}