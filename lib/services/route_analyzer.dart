import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/issue.dart';
import '../models/route_result.dart';

/// Descobre quais ocorrências ficam perto de uma rota (lógica pura, sem interface).
class RouteAnalyzer {
  /// Distância máxima, em metros, para considerar que a ocorrência está "na rota".
  static const double radiusMeters = 150;

  List<RouteIssue> findIssuesAlongRoute(
    List<Issue> issues,
    List<LatLng> route, {
    double radius = radiusMeters,
  }) {
    if (route.length < 2) return [];
    final found = <RouteIssue>[];

    for (final issue in issues) {
      // Converte graus em metros tendo a própria ocorrência como origem (0, 0).
      final metersPerLon = 111320 * cos(issue.latitude * pi / 180);
      const metersPerLat = 110540.0;

      var best = double.infinity;
      var bestIndex = 0;
      for (var i = 0; i < route.length - 1; i++) {
        final ax = (route[i].longitude - issue.longitude) * metersPerLon;
        final ay = (route[i].latitude - issue.latitude) * metersPerLat;
        final bx = (route[i + 1].longitude - issue.longitude) * metersPerLon;
        final by = (route[i + 1].latitude - issue.latitude) * metersPerLat;
        final distance = _distanceFromOriginToSegment(ax, ay, bx, by);
        if (distance < best) {
          best = distance;
          bestIndex = i;
        }
      }

      if (best <= radius) {
        found.add(RouteIssue(
            issue: issue, distanceMeters: best, routePosition: bestIndex));
      }
    }

    // Na ordem em que aparecem ao longo do caminho.
    found.sort((a, b) => a.routePosition.compareTo(b.routePosition));
    return found;
  }

  Map<String, int> countByCategory(List<RouteIssue> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.issue.category] = (counts[item.issue.category] ?? 0) + 1;
    }
    return counts;
  }

  double _distanceFromOriginToSegment(
      double ax, double ay, double bx, double by) {
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    var t = lengthSquared == 0 ? 0.0 : (-(ax * dx + ay * dy)) / lengthSquared;
    t = t.clamp(0.0, 1.0).toDouble();
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return sqrt(cx * cx + cy * cy);
  }
}
