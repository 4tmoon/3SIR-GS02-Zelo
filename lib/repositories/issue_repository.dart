import 'dart:math';

import '../database/app_database.dart';
import '../models/issue.dart';

class IssueRepository {
  IssueRepository._();
  static final IssueRepository instance = IssueRepository._();

  final AppDatabase _db = AppDatabase.instance;

  Future<List<Issue>> fetchAll() => _db.getAll();

  List<Issue> filter(List<Issue> issues, {required String category, required String query}) {
    final text = query.trim().toLowerCase();
    return issues.where((issue) {
      final matchesCategory = category == IssueCategory.filterAll || issue.category == category;
      final matchesText = text.isEmpty ||
          issue.title.toLowerCase().contains(text) ||
          issue.address.toLowerCase().contains(text);
      return matchesCategory && matchesText;
    }).toList();
  }

  List<Issue> officialNotices(List<Issue> issues) =>
      issues.where((issue) => issue.reachedThreshold).toList();

  /// Apoia ou remove o apoio e atualiza o status conforme a meta de 80%.
  Future<Issue> toggleSupport(Issue issue) async {
    final supported = !issue.supportedByMe;
    var updated = issue.copyWith(
      likes: issue.likes + (supported ? 1 : -1),
      supportedByMe: supported,
    );
    updated = updated.copyWith(
      status: updated.reachedThreshold ? IssueStatus.formal : IssueStatus.collecting,
    );
    await _db.update(updated);
    return updated;
  }

  Future<Issue> create({
    required String title,
    required String description,
    required String category,
    required String address,
    String imageData = '',
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random();
    // Localização simulada (centro de SP com pequena variação), pois o app não usa GPS.
    final issue = Issue(
      id: id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      address: address.trim(),
      imageUrl: imageData,
      likes: 1,
      activeRegionalUsers: 50,
      status: IssueStatus.collecting,
      latitude: -23.5505 + (random.nextDouble() - 0.5) * 0.04,
      longitude: -46.6333 + (random.nextDouble() - 0.5) * 0.04,
      supportedByMe: true,
    );
    await _db.insert(issue);
    return issue;
  }
}