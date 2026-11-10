import 'dart:math';

import '../database/app_database.dart';
import '../models/issue.dart';
import '../services/route_service.dart';

/// Regras de negócio das ocorrências (as telas só chamam estes métodos).
class IssueRepository {
  IssueRepository._();
  static final IssueRepository instance = IssueRepository._();

  final AppDatabase _db = AppDatabase.instance;
  final RouteService _geocoder = RouteService();

  Future<List<Issue>> fetchAll() => _db.getAll();

  List<Issue> filter(List<Issue> issues,
      {required String category, required String query}) {
    final text = query.trim().toLowerCase();
    return issues.where((issue) {
      final matchesCategory =
          category == IssueCategory.filterAll || issue.category == category;
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
      status: updated.reachedThreshold
          ? IssueStatus.formal
          : IssueStatus.collecting,
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

    // Localização real a partir do endereço; se a busca falhar, usa uma posição
    // aproximada no centro de SP (com pequena variação para os pinos não se sobreporem).
    final random = Random();
    var latitude = -23.5505 + (random.nextDouble() - 0.5) * 0.04;
    var longitude = -46.6333 + (random.nextDouble() - 0.5) * 0.04;
    try {
      final place =
          await _geocoder.geocode(address, timeout: const Duration(seconds: 8));
      latitude = place.location.latitude;
      longitude = place.location.longitude;
    } catch (_) {}

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
      latitude: latitude,
      longitude: longitude,
      supportedByMe: true,
    );
    await _db.insert(issue);
    return issue;
  }
}
