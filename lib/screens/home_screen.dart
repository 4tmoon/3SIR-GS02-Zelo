import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../models/request_state.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
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
  static const _categories = [IssueCategory.filterAll, ...IssueCategory.all];

  final _repository = IssueRepository.instance;
  final _searchController = TextEditingController();

  List<Issue> _issues = [];
  RequestState _state = RequestState.initial;
  String _category = IssueCategory.filterAll;
  String _query = '';

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
    final created = await Navigator.push<Issue>(
      context,
      MaterialPageRoute(builder: (_) => const CreateIssueScreen()),
    );
    if (!mounted || created == null) return;

    // Aparece na hora, sem esperar nova consulta ao banco.
    setState(() {
      _issues = [created, ..._issues];
      _category = IssueCategory.filterAll;
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ocorrência publicada com sucesso!')),
    );
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
      case RequestState.success:
        final issues = _repository.filter(_issues, category: _category, query: _query);
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
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: _categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          selectedColor: AppColors.primarySoft,
                          onSelected: (_) => setState(() => _category = category),
                        ),
                      ))
                  .toList(),
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