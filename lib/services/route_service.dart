import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_result.dart';
import '../models/route_result.dart';
import 'api_service.dart';

class RouteService {
  static const _walkingUrl = 'https://routing.openstreetmap.de/routed-foot/route/v1/driving';
  static const _drivingUrl = 'https://router.project-osrm.org/route/v1/driving';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': 'ZeloApp/1.0 (projeto academico)',
      };

  Future<dynamic> _getJson(Uri uri, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode != 200) {
        throw ApiException('Serviço indisponível no momento (erro ${response.statusCode}).');
      }
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('A busca demorou demais. Tente novamente.');
    } catch (_) {
      throw const ApiException('Não foi possível conectar. Verifique sua internet.');
    }
  }

  Future<PlaceResult> geocode(String query, {Duration timeout = const Duration(seconds: 15)}) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.replaceAll(' - ', ', ').trim(),
      'format': 'json',
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });
    final data = await _getJson(uri, timeout: timeout);
    if (data is! List || data.isEmpty) {
      throw ApiException('Endereço "$query" não encontrado. Tente incluir a cidade.');
    }
    return PlaceResult.fromJson((data as List).first as Map<String, dynamic>);
  }

  Future<List<RouteResult>> fetchRoutes(LatLng from, LatLng to, TravelMode mode) async {
    final base = mode == TravelMode.walking ? _walkingUrl : _drivingUrl;
    final coords = '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final data = await _getJson(
      Uri.parse('$base/$coords?overview=full&geometries=geojson&alternatives=true'),
    );

    final json = data as Map<String, dynamic>;
    final routes = json['routes'];
    if (json['code'] != 'Ok' || routes is! List || routes.isEmpty) {
      throw const ApiException('Não encontramos uma rota entre os dois pontos.');
    }
    return (routes as List)
        .take(3)
        .map((r) => RouteResult.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ReversePlace> reverseGeocode(LatLng point) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': point.latitude.toString(),
      'lon': point.longitude.toString(),
      'format': 'json',
      'zoom': '18',
      'accept-language': 'pt-BR',
    });
    final data = await _getJson(uri, timeout: const Duration(seconds: 10));
    final json = data as Map<String, dynamic>;
    final parts = <String>[];
    String? postcode;

    final address = json['address'];
    if (address is Map) {
      final road = address['road'] ?? address['pedestrian'] ?? address['footway'] ?? address['path'];
      if (road is String) {
        final number = address['house_number'];
        parts.add(number is String ? '$road, $number' : road);
      }
      final district = address['suburb'] ?? address['neighbourhood'];
      if (district is String) parts.add(district);
      final city = address['city'] ?? address['town'] ?? address['municipality'];
      if (city is String) parts.add(city);

      final rawPostcode = address['postcode'];
      if (rawPostcode is String) {
        final digits = rawPostcode.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length == 8) postcode = '${digits.substring(0, 5)}-${digits.substring(5)}';
      }
    }

    if (parts.isEmpty) {
      final name = (json['display_name'] ?? '') as String;
      if (name.isEmpty) throw const ApiException('Não foi possível descobrir o endereço deste ponto.');
      return ReversePlace(address: name, postcode: postcode);
    }
    return ReversePlace(address: parts.join(', '), postcode: postcode);
  }
}