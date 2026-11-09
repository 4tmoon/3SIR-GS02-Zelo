class IssueCategory {
  static const filterAll = 'Todas';
  static const accessibility = 'Acessibilidade';
  static const safety = 'Segurança';
  static const infrastructure = 'Infraestrutura';
  static const all = [accessibility, safety, infrastructure];
}

class IssueStatus {
  static const collecting = 'Em coleta';
  static const formal = 'Solicitação Formal Gerada';
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
  });

  bool get reachedThreshold => likes >= activeRegionalUsers * thresholdRatio;

  double get progress => activeRegionalUsers == 0
      ? 0.0
      : (likes / activeRegionalUsers).clamp(0.0, 1.0).toDouble();

  Issue copyWith({int? likes, String? status, bool? supportedByMe}) {
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
      };

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
      );
}
