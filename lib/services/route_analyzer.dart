import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../models/issue.dart';
import '../models/route_result.dart';

class RouteAnalyzer {
  static const double radiusMeters = 150;

  List<RouteIssue> findIssuesAlongRoute(
    List<Issue> issues,
    List<LatLng> route, {
    double radius = radiusMeters,
  }) {
    if (route.length < 2) return [];
    final found = <RouteIssue>[];

    for (final issue in issues) {
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
        found.add(RouteIssue(issue: issue, distanceMeters: best, routePosition: bestIndex));
      }
    }

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

  static double metersBetween(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Issue? nearestSimilar(
    List<Issue> issues,
    double latitude,
    double longitude,
    String category, {
    double radius = 100,
  }) {
    Issue? nearest;
    var best = double.infinity;
    for (final issue in issues) {
      if (issue.category != category || issue.decision == IssueDecision.accepted) continue;
      final distance = metersBetween(latitude, longitude, issue.latitude, issue.longitude);
      if (distance <= radius && distance < best) {
        best = distance;
        nearest = issue;
      }
    }
    return nearest;
  }

  List<RouteOption> buildOptions(List<Issue> issues, List<RouteResult> routes) => routes
      .map((route) => RouteOption(route: route, issues: findIssuesAlongRoute(issues, route.points)))
      .toList();

  int mostAccessibleIndex(List<RouteOption> options) {
    var best = 0;
    for (var i = 1; i < options.length; i++) {
      final current = options[i];
      final leader = options[best];
      if (current.issues.length < leader.issues.length ||
          (current.issues.length == leader.issues.length &&
              current.route.durationSeconds < leader.route.durationSeconds)) {
        best = i;
      }
    }
    return best;
  }

  int fastestIndex(List<RouteOption> options) {
    var fastest = 0;
    for (var i = 1; i < options.length; i++) {
      if (options[i].route.durationSeconds < options[fastest].route.durationSeconds) fastest = i;
    }
    return fastest;
  }

  String? comparisonHint(List<RouteOption> options) {
    if (options.length < 2) return null;
    final best = mostAccessibleIndex(options);
    final fastest = fastestIndex(options);
    if (best == fastest) return null;
    final avoided = options[fastest].issues.length - options[best].issues.length;
    if (avoided <= 0) return null;
    final extraMinutes =
        ((options[best].route.durationSeconds - options[fastest].route.durationSeconds) / 60).round();
    final what = avoided == 1 ? 'ocorrência' : 'ocorrências';
    return extraMinutes > 0
        ? 'A rota ${best + 1} evita $avoided $what e leva $extraMinutes min a mais.'
        : 'A rota ${best + 1} evita $avoided $what.';
  }

  double _distanceFromOriginToSegment(double ax, double ay, double bx, double by) {
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