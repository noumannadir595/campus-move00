import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/database.dart';

class DriverLiveLocationScreen extends StatefulWidget {
  const DriverLiveLocationScreen({super.key});
  @override
  State<DriverLiveLocationScreen> createState() =>
      _DriverLiveLocationScreenState();
}

class _DriverLiveLocationScreenState extends State<DriverLiveLocationScreen> {
  Timer? _timer;
  bool _isSharing = false;
  String? _routeId;
  String _routeName = '';
  String _driverName = '';
  String _driverPhone = '';
  String _statusText = 'Ready to start';

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (!userSnap.exists) return;

      final data = Map<String, dynamic>.from(userSnap.value as Map);
      final routeId = data['assignedRoute']?.toString() ?? '';

      String routeName = '';
      if (routeId.isNotEmpty) {
        final routeSnap = await getDatabase().ref('routes/$routeId').get();
        if (routeSnap.exists) {
          final rData = Map<String, dynamic>.from(routeSnap.value as Map);
          routeName = 'Route ${rData['routeNumber']}: ${rData['name']}';
        }
      }

      if (mounted) {
        setState(() {
          _routeId = routeId;
          _routeName = routeName;
          _driverName = data['name']?.toString() ?? '';
          _driverPhone = data['phone']?.toString() ?? '';
        });
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusText = 'Location services OFF');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusText = 'Permission denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _statusText = 'Permission permanently denied');
      return false;
    }
    return true;
  }

  Future<void> _sendLocation() async {
    if (_routeId == null || _routeId!.isEmpty) return;
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await getDatabase().ref('busLocations/$_routeId').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'routeName': _routeName,
        'driverName': _driverName,
        'driverPhone': _driverPhone,
        'driverUid': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
      });

      if (mounted) {
        setState(() {
          _statusText =
              'Live: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusText = 'Error: $e');
      }
    }
  }

  void _startSharing() {
    if (_routeId == null || _routeId!.isEmpty) return;
    setState(() {
      _isSharing = true;
      _statusText = 'Starting...';
    });
    _sendLocation();
    _timer = Timer.periodic(
        const Duration(seconds: 2), (_) => _sendLocation());
  }

  void _stopSharing() {
    _timer?.cancel();
    setState(() {
      _isSharing = false;
      _statusText = 'Stopped';
    });
    if (_routeId != null && _routeId!.isNotEmpty) {
      getDatabase().ref('busLocations/$_routeId').remove();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Live Location'),
        backgroundColor: _isSharing ? Colors.green : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSharing ? Icons.gps_fixed : Icons.gps_off,
                size: 100,
                color: _isSharing ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                _isSharing ? 'LIVE - Sharing Location' : 'Not Sharing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isSharing ? Colors.green : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _routeName.isEmpty ? 'No route assigned' : _routeName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _routeId == null || _routeId!.isEmpty
                    ? null
                    : () async {
                        if (!_isSharing) {
                          if (await _checkPermission()) {
                            _startSharing();
                          }
                        } else {
                          _stopSharing();
                        }
                      },
                icon: Icon(_isSharing ? Icons.stop : Icons.play_arrow),
                label: Text(_isSharing ? 'STOP SHARING' : 'START SHARING'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSharing ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              if (_routeId == null || _routeId!.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Admin se route assign karwani hai',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}