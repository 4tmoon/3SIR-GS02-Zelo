import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../database/app_database.dart';
import '../models/comment.dart';
import '../models/issue.dart';
import '../models/issue_filter.dart';
import '../services/route_analyzer.dart';
import '../services/route_service.dart';

class IssueRepository {
  IssueRepository._();
  static final IssueRepository instance = IssueRepository._();

  final AppDatabase _db = AppDatabase.instance;
  final RouteService _geocoder = RouteService();
  final RouteAnalyzer _analyzer = RouteAnalyzer();

  Future<List<Issue>> fetchAll() => _db.getAll();

  List<Issue> filter(
    List<Issue> issues, {
    required IssueFilter filter,
    required String query,
  }) {
    final text = query.trim().toLowerCase();
    return issues.where((issue) {
      final matchesText = text.isEmpty ||
          issue.title.toLowerCase().contains(text) ||
          issue.address.toLowerCase().contains(text);
      return matchesText && filter.matches(issue);
    }).toList();
  }

  List<Issue> sort(List<Issue> issues, IssueSort order) {
    int byDate(Issue a, Issue b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0);

    int compare(Issue a, Issue b) {
      int result;
      if (order == IssueSort.mostSupported) {
        result = b.likes.compareTo(a.likes);
      } else if (order == IssueSort.nearGoal) {
        // Quem falta menos para a meta vem primeiro; as que já têm ofício vão para o fim.
        final keyA = a.hasNotice ? 1 << 30 : a.supportsMissing;
        final keyB = b.hasNotice ? 1 << 30 : b.supportsMissing;
        result = keyA.compareTo(keyB);
      } else if (order == IssueSort.urgent) {
        result = IssueSeverity.rank(b.severity).compareTo(IssueSeverity.rank(a.severity));
        if (result == 0) result = b.likes.compareTo(a.likes);
      } else {
        result = byDate(a, b);
      }
      return result != 0 ? result : byDate(a, b);
    }

    final sorted = List<Issue>.of(issues);
    sorted.sort(compare);
    return sorted;
  }

  List<Issue> officialNotices(List<Issue> issues) =>
      issues.where((issue) => issue.hasNotice).toList();

  Future<Issue> toggleSupport(Issue issue) async {
    final supported = !issue.supportedByMe;
    var updated = issue.copyWith(
      likes: issue.likes + (supported ? 1 : -1),
      supportedByMe: supported,
    );
    if (updated.reachedAt == null) {
      if (updated.reachedThreshold) {
        final now = DateTime.now();
        updated = updated.copyWith(
          status: IssueStatus.formal,
          reachedAt: now,
          noticeGeneratedAt: now,
        );
      } else {
        updated = updated.copyWith(status: IssueStatus.collecting);
      }
    }
    await _db.update(updated);
    return updated;
  }

  Future<Issue> addSupport(Issue issue) async {
    if (issue.supportedByMe) return issue;
    return toggleSupport(issue);
  }

  Future<LatLng> resolveLocation(String address, {LatLng? picked}) async {
    if (picked != null) return picked;
    try {
      final place = await _geocoder.geocode(address, timeout: const Duration(seconds: 8));
      return place.location;
    } catch (_) {
      // Sem resultado: posição aproximada no centro de SP (com pequena variação).
      final random = Random();
      return LatLng(
        -23.5505 + (random.nextDouble() - 0.5) * 0.04,
        -46.6333 + (random.nextDouble() - 0.5) * 0.04,
      );
    }
  }

  Future<Issue?> findSimilar(LatLng point, String category) async {
    final all = await fetchAll();
    return _analyzer.nearestSimilar(all, point.latitude, point.longitude, category);
  }

  Future<Issue> create({
    required String title,
    required String description,
    required String category,
    required String address,
    required LatLng location,
    String severity = IssueSeverity.medium,
    String imageData = '',
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
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
      latitude: location.latitude,
      longitude: location.longitude,
      supportedByMe: true,
      createdAt: DateTime.now(),
      severity: severity,
    );
    await _db.insert(issue);
    return issue;
  }

  Future<List<Comment>> fetchComments(String issueId) => _db.getComments(issueId);

  Future<Comment> addComment(String issueId, String text) async {
    final now = DateTime.now();
    final comment = Comment(
      id: now.microsecondsSinceEpoch.toString(),
      issueId: issueId,
      author: 'Você',
      text: text.trim(),
      createdAt: now,
    );
    await _db.insertComment(comment);
    return comment;
  }
}