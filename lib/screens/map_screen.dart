import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/issue.dart';
import '../models/issue_filter.dart';
import '../models/place_result.dart';
import '../models/request_state.dart';
import '../models/route_result.dart';
import '../repositories/issue_repository.dart';
import '../services/api_service.dart';
import '../services/route_analyzer.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/issue_card.dart';
import '../widgets/issue_pin.dart';
import '../widgets/map_filter_bar.dart';
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
  IssueFilter _filter = const IssueFilter();

  RequestState _routeState = RequestState.initial;
  String _routeError = '';
  List<RouteResult> _routes = [];
  int _selectedRoute = 0;
  PlaceResult? _originPlace;
  PlaceResult? _destinationPlace;
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

  List<Issue> get _filteredIssues => _issues.where(_filter.matches).toList();

  Future<void> _openFilters() async {
    final result = await showIssueFilterSheet(context, _filter);
    if (result != null && mounted) setState(() => _filter = result);
  }

  Future<void> _loadIssues() async {
    try {
      final data = await _repository.fetchAll();
      if (!mounted) return;
      setState(() => _issues = data);
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
      _routes = [];
    });

    try {
      final origin = await _routeService.geocode(from);
      await Future.delayed(const Duration(milliseconds: 1100));
      final destination = await _routeService.geocode(to);
      final routes = await _routeService.fetchRoutes(origin.location, destination.location, _mode);
      if (!mounted) return;

      final options = _analyzer.buildOptions(_filteredIssues, routes);
      setState(() {
        _originPlace = origin;
        _destinationPlace = destination;
        _routes = routes;
        _selectedRoute = _analyzer.mostAccessibleIndex(options);
        _routeState = RequestState.success;
        _searchExpanded = false;
      });

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(routes.expand((r) => r.points).toList()),
          padding: const EdgeInsets.fromLTRB(32, 140, 32, 270),
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
      _routes = [];
      _selectedRoute = 0;
      _originPlace = null;
      _destinationPlace = null;
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
        width: 40,
        height: 40,
        child: IssuePin(issue: issue, onTap: () => _showIssueSheet(issue)),
      );

  Marker _pointMarker(LatLng point, IconData icon, Color color) => Marker(
        point: point,
        width: 40,
        height: 40,
        child: Icon(icon, size: 32, color: color),
      );

  List<Polyline> _polylines(List<RouteOption> options, int selectedIndex) {
    final lines = <Polyline>[];
    for (var i = 0; i < options.length; i++) {
      if (i != selectedIndex) {
        lines.add(Polyline(
          points: options[i].route.points,
          strokeWidth: 5,
          color: const Color(0xFF9FA8DA),
        ));
      }
    }
    if (options.isNotEmpty) {
      lines.add(Polyline(
        points: options[selectedIndex].route.points,
        strokeWidth: 6,
        color: AppColors.primary,
      ));
    }
    return lines;
  }

  List<Marker> _buildMarkers(RouteOption? selected) {
    final markers = <Marker>[];
    if (_showIssues) {
      // Com rota, mostra só o que está no trajeto; sem rota, mostra todas (já filtradas).
      final visible = selected == null
          ? _filteredIssues
          : selected.issues.map((item) => item.issue).toList();
      markers.addAll(visible.map(_issueMarker));
    }
    final origin = _originPlace;
    final destination = _destinationPlace;
    if (selected != null && origin != null) {
      markers.add(_pointMarker(origin.location, Icons.trip_origin, AppColors.success));
    }
    if (selected != null && destination != null) {
      markers.add(_pointMarker(destination.location, Icons.flag, AppColors.primary));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final options = _routes.isEmpty
        ? <RouteOption>[]
        : _analyzer.buildOptions(_filteredIssues, _routes);
    final selectedIndex = options.isEmpty ? 0 : min(_selectedRoute, options.length - 1);
    final selected = options.isEmpty ? null : options[selectedIndex];
    final bestIndex = options.isEmpty ? 0 : _analyzer.mostAccessibleIndex(options);

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
              if (selected != null && _showIssues)
                CircleLayer(
                  circles: selected.issues
                      .map((item) => CircleMarker(
                            point: LatLng(item.issue.latitude, item.issue.longitude),
                            radius: RouteAnalyzer.radiusMeters,
                            useRadiusInMeter: true,
                            color: const Color(0x22EF6C00),
                            borderColor: AppColors.warning,
                            borderStrokeWidth: 1.5,
                          ))
                      .toList(),
                ),
              if (options.isNotEmpty) PolylineLayer(polylines: _polylines(options, selectedIndex)),
              MarkerLayer(markers: _buildMarkers(selected)),
            ],
          ),
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RouteSearchCard(
                  originController: _originController,
                  destinationController: _destinationController,
                  mode: _mode,
                  showIssues: _showIssues,
                  expanded: _searchExpanded,
                  isLoading: _routeState == RequestState.loading,
                  hasRoute: options.isNotEmpty,
                  onModeChanged: (mode) => setState(() => _mode = mode),
                  onShowIssuesChanged: (value) => setState(() => _showIssues = value),
                  onSubmit: _traceRoute,
                  onClear: _clearRoute,
                  onSwap: _swapPlaces,
                  onToggleExpanded: () => setState(() => _searchExpanded = !_searchExpanded),
                ),
                const SizedBox(height: 6),
                MapFilterBar(
                  filterCount: _filter.activeCount,
                  onFilters: _openFilters,
                  onLegend: () => showMapLegend(context),
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: RouteSummaryPanel(
              state: _routeState,
              options: options,
              selectedIndex: selectedIndex,
              bestIndex: bestIndex,
              hint: _analyzer.comparisonHint(options),
              categoryCounts: selected == null
                  ? <String, int>{}
                  : _analyzer.countByCategory(selected.issues),
              showIssues: _showIssues,
              errorMessage: _routeError,
              onRetry: _traceRoute,
              onOpenIssue: _openIssue,
              onSelectOption: (index) => setState(() => _selectedRoute = index),
            ),
          ),
        ],
      ),
    );
  }
}