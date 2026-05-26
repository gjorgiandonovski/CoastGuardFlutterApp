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
  static const _defaultCenter = LatLng(40.4168, -3.7038);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('beaches').snapshots(),
      builder: (context, snapshot) {
        List<Marker> markers = [];
        LatLng initialCenter = _defaultCenter;

        if (snapshot.hasData) {
          markers = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final lat = (data['latitude'] as num).toDouble();
            final lng = (data['longitude'] as num).toDouble();
            
            return Marker(
              point: LatLng(lat, lng),
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: () => _showBeachInfo(data),
                child: const Icon(Icons.location_pin, size: 44, color: Colors.blue),
              ),
            );
          }).toList();

          if (markers.isNotEmpty) {
            initialCenter = markers.first.point;
          }
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 10,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.project_mad',
            ),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }

  void _showBeachInfo(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Beach'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Municipality: ${data['municipality'] ?? 'N/A'}'),
            Text('Risk Level: ${data['riskLevel'] ?? 'N/A'}'),
            Text('Cleanliness: ${data['cleanlinessScore'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
