import 'package:latlong2/latlong.dart';

import 'issue.dart';

enum TravelMode { walking, driving }

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List;
    return RouteResult(
      // O GeoJSON vem como [longitude, latitude].
      points: coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList(),
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
    );
  }

  String get distanceLabel => distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 1) return 'menos de 1 min';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }
}

class RouteIssue {
  final Issue issue;
  final double distanceMeters;
  final int routePosition;

  const RouteIssue({
    required this.issue,
    required this.distanceMeters,
    required this.routePosition,
  });
}

class RouteOption {
  final RouteResult route;
  final List<RouteIssue> issues;

  const RouteOption({required this.route, required this.issues});
}