class IssueCategory {
  static const filterAll = 'Todas';
  static const accessibility = 'Acessibilidade';
  static const safety = 'Segurança';
  static const infrastructure = 'Infraestrutura';
  static const all = [accessibility, safety, infrastructure];
}

class IssueStatus {
  static const collecting = 'Em Coleta';
  static const formal = 'Solicitação Formal Gerada';
  static const accepted = 'Aceita pela prefeitura';
}

class IssueDecision {
  static const accepted = 'accepted';
}

class Issue {
  /// Percentual de apoio necessário para gerar a solicitação formal.
  static const double thresholdRatio = 0.8;

  final String id;
  final String title;
  final String description;
  final String category;
  final String address;
  final String imageUrl;
  final int likes;
  final int activeRegionalUsers;
  final String status;
  final double latitude;
  final double longitude;
  final bool supportedByMe;

  final DateTime? createdAt;
  final DateTime? reachedAt;
  final DateTime? noticeGeneratedAt;
  final DateTime? decisionAt;
  final String? decision;

  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.address,
    required this.imageUrl,
    required this.likes,
    required this.activeRegionalUsers,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.supportedByMe = false,
    this.createdAt,
    this.reachedAt,
    this.noticeGeneratedAt,
    this.decisionAt,
    this.decision,
  });

  int get goalSupports => (activeRegionalUsers * 8 + 9) ~/ 10;
  int get supportsMissing => likes >= goalSupports ? 0 : goalSupports - likes;
  bool get reachedThreshold => likes >= goalSupports;
  bool get hasNotice => noticeGeneratedAt != null;
  double get progress => activeRegionalUsers == 0
      ? 0.0
      : (likes / activeRegionalUsers).clamp(0.0, 1.0).toDouble();

  Issue copyWith({
    int? likes,
    String? status,
    bool? supportedByMe,
    DateTime? reachedAt,
    DateTime? noticeGeneratedAt,
    DateTime? decisionAt,
    String? decision,
  }) {
    return Issue(
      id: id,
      title: title,
      description: description,
      category: category,
      address: address,
      imageUrl: imageUrl,
      likes: likes ?? this.likes,
      activeRegionalUsers: activeRegionalUsers,
      status: status ?? this.status,
      latitude: latitude,
      longitude: longitude,
      supportedByMe: supportedByMe ?? this.supportedByMe,
      createdAt: createdAt,
      reachedAt: reachedAt ?? this.reachedAt,
      noticeGeneratedAt: noticeGeneratedAt ?? this.noticeGeneratedAt,
      decisionAt: decisionAt ?? this.decisionAt,
      decision: decision ?? this.decision,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'address': address,
        'imageUrl': imageUrl,
        'likes': likes,
        'activeRegionalUsers': activeRegionalUsers,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'supported': supportedByMe ? 1 : 0,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'reachedAt': reachedAt?.millisecondsSinceEpoch,
        'noticeGeneratedAt': noticeGeneratedAt?.millisecondsSinceEpoch,
        'decisionAt': decisionAt?.millisecondsSinceEpoch,
        'decision': decision,
      };

  static DateTime? _toDate(Object? value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);

  factory Issue.fromMap(Map<String, dynamic> map) => Issue(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        category: map['category'] as String,
        address: map['address'] as String,
        imageUrl: map['imageUrl'] as String,
        likes: map['likes'] as int,
        activeRegionalUsers: map['activeRegionalUsers'] as int,
        status: map['status'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        supportedByMe: (map['supported'] ?? 0) == 1,
        createdAt: _toDate(map['createdAt']),
        reachedAt: _toDate(map['reachedAt']),
        noticeGeneratedAt: _toDate(map['noticeGeneratedAt']),
        decisionAt: _toDate(map['decisionAt']),
        decision: map['decision'] as String?,
      );
}