import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../db/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultCenter = LatLng(40.4168, -3.7038);

  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _dbRows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  Future<void> _loadCoordinates() async {
    final rows = await DatabaseHelper.instance.getCoordinates();
    if (!mounted) return;
    setState(() {
      _dbRows = rows;
      _loading = false;
    });
  }

  List<Marker> _buildMarkers() {
    return _dbRows.map((row) {
      final lat = (row['latitude'] as num).toDouble();
      final lng = (row['longitude'] as num).toDouble();
      final ts = row['timestamp'] as String;

      return Marker(
        point: LatLng(lat, lng),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showMarkerInfo(ts, lat, lng),
          child: const Icon(Icons.location_pin, size: 44, color: Colors.red),
        ),
      );
    }).toList();
  }

  void _showMarkerInfo(String timestamp, double lat, double lng) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved coordinate'),
        content: Text('Time: $timestamp\nLat: $lat\nLng: $lng'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Map is not available on web.\nRun on Android or iOS to see your saved coordinates on the map.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _dbRows.isNotEmpty
                ? LatLng(
              (_dbRows.first['latitude'] as num).toDouble(),
              (_dbRows.first['longitude'] as num).toDouble(),
            )
                : _defaultCenter,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.project_mad',
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (!_loading && _dbRows.isEmpty)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('No saved coordinates yet. Capture GPS in the Week 4 tab.'),
                ),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'map_refresh',
            onPressed: _loadCoordinates,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}