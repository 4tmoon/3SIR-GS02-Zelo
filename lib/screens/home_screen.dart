import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/issue_filter.dart';
import '../models/request_state.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/issue_card.dart';
import '../widgets/state_views.dart';
import 'create_issue_screen.dart';
import 'issue_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _sortLabels = {
    IssueSort.recent: 'Mais recentes',
    IssueSort.mostSupported: 'Mais apoiadas',
    IssueSort.nearGoal: 'Perto da meta',
    IssueSort.urgent: 'Mais urgentes',
  };

  final _repository = IssueRepository.instance;
  final _searchController = TextEditingController();

  List<Issue> _issues = [];
  RequestState _state = RequestState.initial;
  IssueFilter _filter = const IssueFilter();
  String _query = '';
  IssueSort _sort = IssueSort.recent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _state = RequestState.loading);
    try {
      final data = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _issues = data;
        _state = RequestState.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = RequestState.error);
    }
  }

  void _replaceIssue(Issue updated) {
    setState(() {
      _issues = _issues.map((i) => i.id == updated.id ? updated : i).toList();
    });
  }

  void _openDetail(Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailScreen(issue: issue, onChanged: _replaceIssue),
      ),
    );
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<Issue>(
      context,
      MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
    );
    if (!mounted || result == null) return;

    final alreadyListed = _issues.any((i) => i.id == result.id);
    setState(() {
      _issues = alreadyListed
          ? _issues.map((i) => i.id == result.id ? result : i).toList()
          : [result, ..._issues];
      _filter = const IssueFilter();
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alreadyListed
            ? 'Apoio registrado na ocorrência existente.'
            : 'Ocorrência publicada com sucesso!'),
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showIssueFilterSheet(context, _filter);
    if (result != null && mounted) setState(() => _filter = result);
  }

  Widget _buildList() {
    switch (_state) {
      case RequestState.initial:
      case RequestState.loading:
        return const LoadingView();
      case RequestState.error:
        return ErrorView(
          message: 'Não foi possível carregar as ocorrências.',
          onRetry: _load,
        );
      default:
        final issues = _repository.sort(
          _repository.filter(_issues, filter: _filter, query: _query),
          _sort,
        );
        if (issues.isEmpty) {
          return const EmptyView(
            icon: Icons.search_off,
            message: 'Nenhuma ocorrência encontrada.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => _load(silent: true),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 88),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => IssueCard(
              issue: issues[index],
              onTap: () => _openDetail(issues[index]),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zelo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: appInputDecoration(
                      label: 'Buscar por título ou endereço',
                      icon: Icons.search,
                      suffix: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                PopupMenuButton<IssueSort>(
                  tooltip: 'Ordenar',
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => _sortLabels.entries
                      .map((entry) => CheckedPopupMenuItem<IssueSort>(
                            value: entry.key,
                            checked: _sort == entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.sort, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterButton(count: _filter.activeCount, onPressed: _openFilters),
              ],
            ),
          ),
          if (!_filter.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ActiveFilterChips(
                  filter: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
    );
  }
}