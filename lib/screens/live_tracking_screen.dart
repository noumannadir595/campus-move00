import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Bus Tracking')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('busLocations').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bus_alert, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Koi bus online nahi hai'),
                  SizedBox(height: 8),
                  Text(
                      'Driver jab live location start karega,\nto yahan dikhega',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final newMarkers = <Marker>{};

          data.forEach((busId, value) {
            final loc = Map<dynamic, dynamic>.from(value);
            final lat = (loc['lat'] as num).toDouble();
            final lng = (loc['lng'] as num).toDouble();
            final ts = loc['timestamp'] ?? 0;

            final age = DateTime.now().millisecondsSinceEpoch - ts;
            if (age > 120000) return;

            newMarkers.add(
              Marker(
                markerId: MarkerId(busId.toString()),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(title: 'Bus: $busId'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure),
              ),
            );
          });

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(31.4479, 74.5299),
                  zoom: 13,
                ),
                markers: newMarkers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Text(
                      'Active Buses: ${newMarkers.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}