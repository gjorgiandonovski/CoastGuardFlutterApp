import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('beaches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final beaches = snapshot.data?.docs ?? [];
                
                final filteredBeaches = beaches.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_selectedFilter == 'High Risk') return data['riskLevel']?.toString().toLowerCase() == 'high';
                  if (_selectedFilter == 'Medium Risk') return data['riskLevel']?.toString().toLowerCase() == 'medium';
                  if (_selectedFilter == 'Low Risk') return data['riskLevel']?.toString().toLowerCase() == 'low';
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
                          final data = filteredBeaches[index].data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRiskColor(data['riskLevel']).withOpacity(0.1),
                                child: Icon(Icons.beach_access, color: _getRiskColor(data['riskLevel'])),
                              ),
                              title: Text(data['name'] ?? 'Unnamed Beach', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Municipality: ${data['municipality'] ?? 'N/A'}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${data['cleanlinessScore'] ?? '?'}/100', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Clean', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                              onTap: () {
                                if (data['latitude'] != null && data['longitude'] != null) {
                                  _mapController.move(LatLng((data['latitude'] as num).toDouble(), (data['longitude'] as num).toDouble()), 14);
                                }
                                _showBeachDetails(data);
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

  List<Marker> _buildMarkers(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['latitude'] != null && data['longitude'] != null;
    }).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Marker(
        point: LatLng((data['latitude'] as num).toDouble(), (data['longitude'] as num).toDouble()),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showBeachDetails(data),
          child: Icon(Icons.location_on, size: 45, color: _getRiskColor(data['riskLevel'])),
        ),
      );
    }).toList();
  }

  void _showBeachDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['name'] ?? 'Beach Details', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            _infoRow(Icons.map, 'Municipality', data['municipality']),
            _infoRow(Icons.warning, 'Risk Level', data['riskLevel']),
            _infoRow(Icons.star, 'Cleanliness', '${data['cleanlinessScore']}/100'),
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
