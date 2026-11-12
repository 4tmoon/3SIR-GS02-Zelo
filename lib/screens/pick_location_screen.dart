import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';
import '../widgets/app_card.dart';


class PickLocationScreen extends StatefulWidget {
  final LatLng? center;
  final LatLng? selected;
  final double zoom;

  const PickLocationScreen({super.key, this.center, this.selected, this.zoom = 14});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final hasStreet = widget.center != null && widget.selected == null;
    return Scaffold(
      appBar: AppBar(title: const Text('Marcar local')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.selected ?? widget.center ?? const LatLng(-23.5505, -46.6333),
              initialZoom: widget.zoom,
              onTap: (_, point) => setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zelo.app',
              ),
              if (selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_on, size: 44, color: AppColors.danger),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    selected == null
                        ? (hasStreet
                            ? 'O mapa abriu na rua informada. Toque no ponto exato do problema.'
                            : 'Toque no mapa para marcar o local do problema.')
                        : 'Local marcado: ${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Confirmar local'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}