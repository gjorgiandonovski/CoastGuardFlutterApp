import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/beach.dart';
import '../services/beach_api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final BeachApiService _beachApiService = BeachApiService();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'High Risk',
    'Medium Risk',
    'Low Risk',
  ];

  Color _getRiskColor(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<Beach>>(
              stream: _beachApiService.watchBeaches(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final beaches = snapshot.data ?? const <Beach>[];

                final filteredBeaches = beaches.where((beach) {
                  final riskLevel = beach.riskLevel?.toLowerCase();
                  if (_selectedFilter == 'High Risk') return riskLevel == 'high';
                  if (_selectedFilter == 'Medium Risk') return riskLevel == 'medium';
                  if (_selectedFilter == 'Low Risk') return riskLevel == 'low';
                  return true;
                }).toList();

                final markers = _buildMarkers(filteredBeaches);

                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: markers.isNotEmpty ? markers.first.point : const LatLng(40.4168, -3.7038),
                          initialZoom: 10,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.project_mad',
                          ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredBeaches.length,
                        itemBuilder: (context, index) {
                          final beach = filteredBeaches[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRiskColor(
                                  beach.riskLevel,
                                ).withValues(alpha: 0.1),
                                child: Icon(Icons.beach_access, color: _getRiskColor(beach.riskLevel)),
                              ),
                              title: Text(beach.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Municipality: ${beach.municipality ?? 'N/A'}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${beach.cleanlinessScore ?? '?'}/100', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Clean', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                              onTap: () {
                                if (beach.hasCoordinates) {
                                  _mapController.move(LatLng(beach.latitude!, beach.longitude!), 14);
                                }
                                _showBeachDetails(beach);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Marker> _buildMarkers(List<Beach> beaches) {
    return beaches.where((beach) => beach.hasCoordinates).map((beach) {
      return Marker(
        point: LatLng(beach.latitude!, beach.longitude!),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showBeachDetails(beach),
          child: Icon(Icons.location_on, size: 45, color: _getRiskColor(beach.riskLevel)),
        ),
      );
    }).toList();
  }

  void _showBeachDetails(Beach beach) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(beach.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _infoRow(Icons.map, 'Municipality', beach.municipality),
            _infoRow(Icons.warning, 'Risk Level', beach.riskLevel),
            _infoRow(Icons.star, 'Cleanliness', '${beach.cleanlinessScore ?? '?'}/100'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value?.toString() ?? 'N/A'),
        ],
      ),
    );
  }
}
