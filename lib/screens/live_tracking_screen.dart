import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/database.dart';
import '../theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: getDatabase().ref('routes').onValue,
        builder: (context, routesSnap) {
          return StreamBuilder<DatabaseEvent>(
            stream: getDatabase().ref('busLocations').onValue,
            builder: (context, busesSnap) {
              if (!routesSnap.hasData ||
                  routesSnap.data!.snapshot.value == null) {
                return _buildEmptyState();
              }

              final routesData =
                  routesSnap.data!.snapshot.value as Map<dynamic, dynamic>;

              Map<dynamic, dynamic> busesData = {};
              if (busesSnap.hasData &&
                  busesSnap.data!.snapshot.value != null) {
                busesData =
                    busesSnap.data!.snapshot.value as Map<dynamic, dynamic>;
              }

              final now = DateTime.now().millisecondsSinceEpoch;

              // Build route list with both directions
              final routeList = <Map<String, dynamic>>[];
              routesData.forEach((routeId, routeValue) {
                try {
                  final route = Map<dynamic, dynamic>.from(routeValue);

                  final routeNumber =
                      route['routeNumber']?.toString() ?? '';
                  final routeName = route['name']?.toString() ?? '';

                  // Generate directions from route name
                  String dirALabel = '';
                  String dirBLabel = '';
                  try {
                    String cleanName = routeName;
                    if (cleanName.contains(': ')) {
                      cleanName = cleanName.split(': ')[1];
                    }
                    if (cleanName.contains(' - ')) {
                      final parts = cleanName.split(' - ');
                      if (parts.length >= 2) {
                        dirALabel = '${parts[0]} → ${parts[1]}';
                        dirBLabel = '${parts[1]} → ${parts[0]}';
                      }
                    }
                  } catch (_) {}
                  if (dirALabel.isEmpty) {
                    dirALabel = 'Direction A';
                    dirBLabel = 'Direction B';
                  }

                  // Check bus locations for both directions
                  Map<dynamic, dynamic>? activeA;
                  Map<dynamic, dynamic>? activeB;

                  busesData.forEach((busRouteId, busValue) {
                    if (busRouteId.toString() != routeId.toString()) return;
                    try {
                      final bus = Map<dynamic, dynamic>.from(busValue);
                      final ts = (bus['timestamp'] ?? 0) as int;
                      final age = now - ts;
                      if (age < 60000 && bus['isActive'] == true) {
                        if (bus['direction'] == 'A') {
                          activeA = bus;
                        } else if (bus['direction'] == 'B') {
                          activeB = bus;
                        }
                      }
                    } catch (_) {}
                  });

                  routeList.add({
                    'routeId': routeId.toString(),
                    'routeNumber': routeNumber,
                    'routeName': routeName,
                    'dirALabel': dirALabel,
                    'dirBLabel': dirBLabel,
                    'activeA': activeA,
                    'activeB': activeB,
                    'startLat': route['startLat'],
                    'startLng': route['startLng'],
                    'endLat': route['endLat'],
                    'endLng': route['endLng'],
                    'isActive': activeA != null || activeB != null,
                  });
                } catch (_) {}
              });

              // Sort: active first, then by route number
              routeList.sort((a, b) {
                final aActive = a['isActive'] == true ? 0 : 1;
                final bActive = b['isActive'] == true ? 0 : 1;
                if (aActive != bActive) return aActive.compareTo(bActive);

                final aNum =
                    int.tryParse(a['routeNumber']?.toString() ?? '') ?? 999;
                final bNum =
                    int.tryParse(b['routeNumber']?.toString() ?? '') ?? 999;
                return aNum.compareTo(bNum);
              });

              final activeRoutes =
                  routeList.where((r) => r['isActive'] == true).toList();
              final offlineRoutes =
                  routeList.where((r) => r['isActive'] != true).toList();

              if (routeList.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(
                      const Duration(milliseconds: 500));
                },
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: activeRoutes.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${activeRoutes.length} Active ${activeRoutes.length == 1 ? "Route" : "Routes"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // LIVE ROUTES SECTION
                    if (activeRoutes.isNotEmpty) ...[
                      _sectionHeader(
                        'Live Routes',
                        Icons.gps_fixed,
                        Colors.green,
                      ),
                      ...activeRoutes.map((r) => _buildRouteCard(r)),
                      const SizedBox(height: 20),
                    ],

                    // OFFLINE ROUTES SECTION
                    if (offlineRoutes.isNotEmpty) ...[
                      _sectionHeader(
                        'Offline Routes',
                        Icons.gps_off,
                        Colors.grey,
                      ),
                      ...offlineRoutes.map((r) => _buildRouteCard(r)),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isActive = route['isActive'] == true;
    final activeA = route['activeA'] as Map<dynamic, dynamic>?;
    final activeB = route['activeB'] as Map<dynamic, dynamic>?;

    return Card(
      elevation: isActive ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade700,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade600,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.route,
                          color: Colors.white, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        route['routeNumber']?.toString() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['routeName']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green
                              : Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'OFFLINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // DIRECTION A
            _buildDirectionTile(
              routeId: route['routeId'],
              routeName: route['routeName'],
              label: route['dirALabel'],
              direction: 'A',
              activeBus: activeA,
              icon: Icons.arrow_forward_rounded,
              route: route,
            ),

            const SizedBox(height: 10),

            // DIRECTION B
            _buildDirectionTile(
              routeId: route['routeId'],
              routeName: route['routeName'],
              label: route['dirBLabel'],
              direction: 'B',
              activeBus: activeB,
              icon: Icons.arrow_back_rounded,
              route: route,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionTile({
    required String routeId,
    required String routeName,
    required String label,
    required String direction,
    required Map<dynamic, dynamic>? activeBus,
    required IconData icon,
    required Map<String, dynamic> route,
  }) {
    final isLive = activeBus != null;

    return GestureDetector(
      onTap: () {
        if (isLive) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusMapView(
                routeId: routeId,
                routeName: routeName,
                direction: direction,
                directionLabel: label,
                startLat: route['startLat'],
                startLng: route['startLng'],
                endLat: route['endLat'],
                endLng: route['endLng'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.grey.shade800,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bus is offline for this direction',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLive
              ? Colors.green.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLive
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLive
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isLive ? Colors.green.shade700 : Colors.grey,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isLive ? FontWeight.w700 : FontWeight.w500,
                      color: isLive ? Colors.green.shade800 : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isLive) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            activeBus['driverName']?.toString() ?? 'Driver',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(activeBus['timestamp'] ?? 0),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 3),
                    Text(
                      'No active bus',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLive ? Colors.green : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isLive ? 'LIVE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isLive ? Colors.green.shade700 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No routes available',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Admin should add routes first',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff < 5000) return 'Just now';
    if (diff < 60000) return '${(diff / 1000).toInt()}s ago';
    return '${(diff / 60000).toInt()}m ago';
  }
}

// ==================== BUS MAP VIEW ====================
class BusMapView extends StatefulWidget {
  final String routeId;
  final String routeName;
  final String direction;
  final String directionLabel;
  final dynamic startLat;
  final dynamic startLng;
  final dynamic endLat;
  final dynamic endLng;

  const BusMapView({
    super.key,
    required this.routeId,
    required this.routeName,
    required this.direction,
    required this.directionLabel,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  @override
  State<BusMapView> createState() => _BusMapViewState();
}

class _BusMapViewState extends State<BusMapView> {
  GoogleMapController? _mapController;
  LatLng? _lastPosition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.routeName, style: const TextStyle(fontSize: 14)),
            Text(widget.directionLabel,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream:
            getDatabase().ref('busLocations/${widget.routeId}').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return _buildOfflineView();
          }

          final loc = Map<dynamic, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          final ts = (loc['timestamp'] ?? 0) as int;
          final age = DateTime.now().millisecondsSinceEpoch - ts;

          if (age > 60000 ||
              loc['isActive'] != true ||
              loc['direction'] != widget.direction) {
            return _buildOfflineView();
          }

          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final busPosition = LatLng(lat, lng);

          if (_lastPosition == null ||
              _lastPosition!.latitude != lat ||
              _lastPosition!.longitude != lng) {
            _lastPosition = busPosition;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(busPosition),
              );
            });
          }

          // Build polyline
          final polylines = <Polyline>{};
          if (widget.startLat != null &&
              widget.startLng != null &&
              widget.endLat != null &&
              widget.endLng != null) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route_line'),
                points: [
                  LatLng((widget.startLat as num).toDouble(),
                      (widget.startLng as num).toDouble()),
                  LatLng((widget.endLat as num).toDouble(),
                      (widget.endLng as num).toDouble()),
                ],
                color: AppColors.primary,
                width: 5,
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: busPosition,
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  Marker(
                    markerId: const MarkerId('bus'),
                    position: busPosition,
                    infoWindow: InfoWindow(
                      title: loc['routeName']?.toString() ??
                          widget.routeName,
                      snippet: 'Driver: ${loc['driverName'] ?? 'N/A'}',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                  ),
                },
                polylines: polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),

              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              loc['routeName']?.toString() ??
                                  widget.routeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            widget.direction == 'A'
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.directionLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            loc['driverName']?.toString() ?? 'Driver',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _timeAgo(ts),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 72,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bus is offline',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This direction is no longer active',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff < 5000) return 'Just now';
    if (diff < 60000) return '${(diff / 1000).toInt()}s ago';
    return '${(diff / 60000).toInt()}m ago';
  }
}