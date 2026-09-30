import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';

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
  String _routeNumber = '';
  String _driverName = '';
  String _driverPhone = '';
  String _statusText = 'Select direction & start';
  String _selectedDirection = ''; // 'A' or 'B'
  String _directionALabel = '';
  String _directionBLabel = '';

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (!userSnap.exists) return;

      final data = Map<String, dynamic>.from(userSnap.value as Map);
      final routeId = data['assignedRoute']?.toString() ?? '';

      String routeName = '';
      String routeNumber = '';
      String dirA = '';
      String dirB = '';

      if (routeId.isNotEmpty) {
        final routeSnap = await getDatabase().ref('routes/$routeId').get();
        if (routeSnap.exists) {
          final rData = Map<String, dynamic>.from(routeSnap.value as Map);
          routeName = rData['name']?.toString() ?? '';
          routeNumber = rData['routeNumber']?.toString() ?? '';

          // Auto-generate directions from route name
          // Format: "Route 1: CUI - Sahiwal"
          try {
            String cleanName = routeName;
            // Remove "Route X: " prefix
            if (cleanName.contains(': ')) {
              cleanName = cleanName.split(': ')[1];
            }
            // Split by " - "
            if (cleanName.contains(' - ')) {
              final parts = cleanName.split(' - ');
              if (parts.length >= 2) {
                dirA = '${parts[0]} → ${parts[1]}';
                dirB = '${parts[1]} → ${parts[0]}';
              }
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _routeId = routeId;
          _routeName = routeName;
          _routeNumber = routeNumber;
          _directionALabel = dirA.isEmpty ? 'Going' : dirA;
          _directionBLabel = dirB.isEmpty ? 'Returning' : dirB;
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

      final directionLabel = _selectedDirection == 'A'
          ? _directionALabel
          : _directionBLabel;

      await getDatabase().ref('busLocations/$_routeId').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'routeName': _routeName,
        'routeNumber': _routeNumber,
        'driverName': _driverName,
        'driverPhone': _driverPhone,
        'driverUid': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isActive': true,
        'direction': _selectedDirection,
        'directionLabel': directionLabel,
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
    if (_selectedDirection.isEmpty) {
      CustomSnackbar.warning(context, 'Please select a direction first');
      return;
    }
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

  Future<void> _selectDirection() async {
    if (_routeId == null || _routeId!.isEmpty) return;
    if (_isSharing) {
      CustomSnackbar.warning(context, 'Stop sharing first to change direction');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Direction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _routeName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _directionTile('A', _directionALabel, Icons.arrow_forward_rounded),
            const SizedBox(height: 10),
            _directionTile('B', _directionBLabel, Icons.arrow_back_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedDirection = selected;
      });
    }
  }

  Widget _directionTile(String value, String label, IconData icon) {
    final isSelected = _selectedDirection == value;
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _selectedDirection == 'A'
        ? _directionALabel
        : (_selectedDirection == 'B' ? _directionBLabel : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Live Location'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _isSharing
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  )
                : AppColors.primaryGradient,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isSharing
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isSharing ? Icons.gps_fixed : Icons.gps_off,
                  size: 64,
                  color: _isSharing ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isSharing ? 'LIVE - Sharing Location' : 'Not Sharing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isSharing ? Colors.green : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Route Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.route,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Route',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              _routeName.isEmpty ? 'Not assigned' : _routeName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Direction Selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isSharing ? null : _selectDirection,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _selectedDirection.isEmpty
                                ? Colors.grey.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _selectedDirection.isEmpty
                                ? Icons.swap_horiz
                                : (_selectedDirection == 'A'
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded),
                            color: _selectedDirection.isEmpty
                                ? Colors.grey
                                : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Direction',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                _selectedDirection.isEmpty
                                    ? 'Tap to select direction'
                                    : selectedLabel,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedDirection.isEmpty
                                      ? Colors.grey
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _isSharing ? Colors.grey.shade300 : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // START/STOP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _routeId == null || _routeId!.isEmpty
                      ? null
                      : () async {
                          if (!_isSharing) {
                            if (_selectedDirection.isEmpty) {
                              CustomSnackbar.warning(
                                  context, 'Please select a direction first');
                              return;
                            }
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
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