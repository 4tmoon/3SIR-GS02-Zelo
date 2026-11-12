import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/issue.dart';
import '../models/place_result.dart';
import '../models/request_state.dart';
import '../models/route_result.dart';
import '../repositories/issue_repository.dart';
import '../services/api_service.dart';
import '../services/route_analyzer.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/issue_card.dart';
import '../widgets/route_search_card.dart';
import '../widgets/route_summary_panel.dart';
import 'issue_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repository = IssueRepository.instance;
  final _routeService = RouteService();
  final _analyzer = RouteAnalyzer();
  final _mapController = MapController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  List<Issue> _issues = [];
  RequestState _routeState = RequestState.initial;
  String _routeError = '';
  RouteResult? _route;
  PlaceResult? _originPlace;
  PlaceResult? _destinationPlace;
  List<RouteIssue> _routeIssues = [];
  TravelMode _mode = TravelMode.walking;
  bool _showIssues = true;
  bool _searchExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    try {
      final data = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _issues = data;
        final route = _route;
        if (route != null) {
          _routeIssues = _analyzer.findIssuesAlongRoute(data, route.points);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível carregar as ocorrências.'),
          action: SnackBarAction(label: 'Tentar novamente', onPressed: _loadIssues),
        ),
      );
    }
  }

  Future<void> _traceRoute() async {
    final from = _originController.text.trim();
    final to = _destinationController.text.trim();
    if (from.isEmpty || to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a partida e a chegada.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _routeState = RequestState.loading;
      _route = null;
      _routeIssues = [];
    });

    try {
      final origin = await _routeService.geocode(from);
      // Política de uso do Nominatim: no máximo 1 requisição por segundo.
      await Future.delayed(const Duration(milliseconds: 1100));
      final destination = await _routeService.geocode(to);
      final route = await _routeService.fetchRoute(origin.location, destination.location, _mode);
      if (!mounted) return;

      setState(() {
        _originPlace = origin;
        _destinationPlace = destination;
        _route = route;
        _routeIssues = _analyzer.findIssuesAlongRoute(_issues, route.points);
        _routeState = RequestState.success;
        _searchExpanded = false;
      });

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route.points),
          padding: const EdgeInsets.fromLTRB(32, 110, 32, 240),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _routeError = e.message;
        _routeState = RequestState.error;
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _originController.clear();
      _destinationController.clear();
      _route = null;
      _originPlace = null;
      _destinationPlace = null;
      _routeIssues = [];
      _routeState = RequestState.initial;
      _searchExpanded = true;
    });
  }

  void _swapPlaces() {
    final origin = _originController.text;
    _originController.text = _destinationController.text;
    _destinationController.text = origin;
  }

  Future<void> _openIssue(Issue issue) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
    );
    if (mounted) _loadIssues();
  }

  void _showIssueSheet(Issue issue) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IssueCard(
              issue: issue,
              onTap: () {
                Navigator.pop(sheetContext);
                _openIssue(issue);
              },
            ),
          ],
        ),
      ),
    );
  }

  Marker _issueMarker(Issue issue) => Marker(
        point: LatLng(issue.latitude, issue.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showIssueSheet(issue),
          child: Icon(
            Icons.location_on,
            size: 40,
            color: issue.hasNotice ? AppColors.success : AppColors.danger,
          ),
        ),
      );

  Marker _pointMarker(LatLng point, IconData icon, Color color) => Marker(
        point: point,
        width: 40,
        height: 40,
        child: Icon(icon, size: 32, color: color),
      );

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_showIssues) {
      // Com rota, mostra só o que está no trajeto; sem rota, mostra todas.
      final visible = _route == null ? _issues : _routeIssues.map((r) => r.issue).toList();
      markers.addAll(visible.map(_issueMarker));
    }
    final origin = _originPlace;
    final destination = _destinationPlace;
    if (_route != null && origin != null) {
      markers.add(_pointMarker(origin.location, Icons.trip_origin, AppColors.success));
    }
    if (_route != null && destination != null) {
      markers.add(_pointMarker(destination.location, Icons.flag, AppColors.primary));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa e rotas')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-23.5505, -46.6333),
              initialZoom: 13.0,
              onTap: (_, __) => FocusScope.of(context).unfocus(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zelo.app',
              ),
              if (route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(points: route.points, strokeWidth: 5, color: AppColors.primary),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: RouteSearchCard(
              originController: _originController,
              destinationController: _destinationController,
              mode: _mode,
              showIssues: _showIssues,
              expanded: _searchExpanded,
              isLoading: _routeState == RequestState.loading,
              hasRoute: route != null,
              onModeChanged: (mode) => setState(() => _mode = mode),
              onShowIssuesChanged: (value) => setState(() => _showIssues = value),
              onSubmit: _traceRoute,
              onClear: _clearRoute,
              onSwap: _swapPlaces,
              onToggleExpanded: () => setState(() => _searchExpanded = !_searchExpanded),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: RouteSummaryPanel(
              state: _routeState,
              route: route,
              issues: _routeIssues,
              categoryCounts: _analyzer.countByCategory(_routeIssues),
              showIssues: _showIssues,
              errorMessage: _routeError,
              onRetry: _traceRoute,
              onOpenIssue: _openIssue,
            ),
          ),
        ],
      ),
    );
  }
}