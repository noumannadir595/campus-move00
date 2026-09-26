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

class _DriverLiveLocationScreenState
    extends State<DriverLiveLocationScreen> {
  Timer? _timer;
  bool _isSharing = false;
  String? _busId;
  String _statusText = 'Ready';

  @override
  void initState() {
    super.initState();
    _loadBusId();
  }

  Future<void> _loadBusId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('users/$uid').get();
    if (snap.exists) {
      setState(() {
        _busId = (snap.value as Map)['busId']?.toString();
      });
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
    if (_busId == null) return;
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await getDatabase().ref('busLocations/$_busId').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'driverUid': FirebaseAuth.instance.currentUser!.uid,
      });

      setState(() {
        _statusText =
            'Sent: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _statusText = 'Error: $e');
    }
  }

  void _startSharing() {
    if (_busId == null) return;
    setState(() => _isSharing = true);
    _sendLocation();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _sendLocation());
  }

  void _stopSharing() {
    _timer?.cancel();
    setState(() {
      _isSharing = false;
      _statusText = 'Stopped';
    });
    if (_busId != null) {
      getDatabase().ref('busLocations/$_busId').remove();
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
      appBar: AppBar(title: const Text('Live Location Sharing')),
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
                _isSharing ? 'Location sharing ON' : 'Location sharing OFF',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Bus ID: ${_busId ?? "Not assigned"}'),
              const SizedBox(height: 12),
              Text(_statusText,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _busId == null
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              if (_busId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'Admin se bus ID assign karwani hai',
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