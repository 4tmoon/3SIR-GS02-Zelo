import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_result.dart';
import '../models/route_result.dart';
import 'api_service.dart';

/// Consome as APIs REST de geocodificação (Nominatim) e rotas (OSRM).
class RouteService {
  static const _walkingUrl =
      'https://routing.openstreetmap.de/routed-foot/route/v1/driving';
  static const _drivingUrl = 'https://router.project-osrm.org/route/v1/driving';

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': 'ZeloApp/1.0 (projeto academico)',
      };

  Future<dynamic> _getJson(Uri uri,
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode != 200) {
        throw ApiException(
            'Serviço indisponível no momento (erro ${response.statusCode}).');
      }
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('A busca demorou demais. Tente novamente.');
    } catch (_) {
      throw const ApiException(
          'Não foi possível conectar. Verifique sua internet.');
    }
  }

  /// Converte um endereço em coordenadas.
  Future<PlaceResult> geocode(String query,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query.replaceAll(' - ', ', ').trim(),
      'format': 'json',
      'limit': '1',
      'countrycodes': 'br',
      'accept-language': 'pt-BR',
    });
    final data = await _getJson(uri, timeout: timeout);
    if (data is! List || data.isEmpty) {
      throw ApiException(
          'Endereço "$query" não encontrado. Tente incluir a cidade.');
    }
    return PlaceResult.fromJson((data as List).first as Map<String, dynamic>);
  }

  /// Busca a rota entre dois pontos.
  Future<RouteResult> fetchRoute(
      LatLng from, LatLng to, TravelMode mode) async {
    final base = mode == TravelMode.walking ? _walkingUrl : _drivingUrl;
    final coords =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final data = await _getJson(
        Uri.parse('$base/$coords?overview=full&geometries=geojson'));

    final json = data as Map<String, dynamic>;
    final routes = json['routes'];
    if (json['code'] != 'Ok' || routes is! List || routes.isEmpty) {
      throw const ApiException(
          'Não encontramos uma rota entre os dois pontos.');
    }
    return RouteResult.fromJson((routes as List).first as Map<String, dynamic>);
  }
}
