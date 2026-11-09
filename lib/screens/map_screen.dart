import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/issue.dart';
import '../repositories/issue_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/issue_card.dart';
import '../widgets/state_views.dart';
import 'issue_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<Issue>> _future;

  @override
  void initState() {
    super.initState();
    _future = IssueRepository.instance.fetchAll();
  }

  void _reload() => setState(() => _future = IssueRepository.instance.fetchAll());

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
              onTap: () async {
                Navigator.pop(sheetContext);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => IssueDetailScreen(issue: issue)),
                );
                if (mounted) _reload();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView();
          if (snapshot.hasError) {
            return ErrorView(message: 'Não foi possível carregar o mapa.', onRetry: _reload);
          }
          final issues = snapshot.data ?? [];
          return FlutterMap(
            options: MapOptions(initialCenter: const LatLng(-23.5505, -46.6333), initialZoom: 13.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zelo.app',
              ),
              MarkerLayer(
                markers: issues
                    .map((issue) => Marker(
                          point: LatLng(issue.latitude, issue.longitude),
                          width: 44,
                          height: 44,
                          child: GestureDetector(
                            onTap: () => _showIssueSheet(issue),
                            child: Icon(
                              Icons.location_on,
                              size: 40,
                              color: issue.reachedThreshold ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
