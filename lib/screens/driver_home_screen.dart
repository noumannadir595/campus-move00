import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/database.dart';
import 'driver_live_location_screen.dart';
import 'login_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Map<String, dynamic>? _driverData;
  bool _loading = true;
  String? _routeNumber;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (userSnap.exists && (userSnap.value as Map)['role'] == 'driver') {
        setState(() {
          _driverData = Map<String, dynamic>.from(userSnap.value as Map);
          _loading = false;
        });
        await _loadRouteNumber();
        return;
      }
      final appSnap = await getDatabase()
          .ref('driverApplications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();
      if (appSnap.exists) {
        final apps = appSnap.value as Map<dynamic, dynamic>;
        if (apps.isNotEmpty) {
          final app = Map<String, dynamic>.from(apps.values.first);
          if (app['status'] == 'approved') {
            setState(() {
              _driverData = app;
              _loading = false;
            });
            await _loadRouteNumber();
            return;
          }
        }
      }
      setState(() {
        _driverData = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _driverData = null;
      });
    }
  }

  Future<void> _loadRouteNumber() async {
    if (_driverData == null) return;
    final routeId = _driverData?['routeId'] ?? _driverData?['assignedRoute'];
    if (routeId == null) return;
    final snap = await getDatabase().ref('routes/$routeId').get();
    if (snap.exists) {
      setState(() {
        _routeNumber = (snap.value as Map)['routeNumber']?.toString() ?? '';
      });
    }
  }

  void _generateQR() {
    if (_driverData == null) return;
    final routeId = _driverData?['routeId'] ?? _driverData?['assignedRoute'];
    if (routeId == null) return;
    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final qrData =
        'CAMPUS_MOVE_ATTENDANCE|$sessionId|$routeId|${DateTime.now().toIso8601String()}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: qrData, size: 200),
              const SizedBox(height: 16),
              Text('Valid for 1 hour - Route ${_routeNumber ?? ''}'),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
    getDatabase().ref('attendanceSessions/$sessionId').set({
      'route': routeId,
      'expiry':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_driverData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Your application is pending or rejected.'),
              Text('Please contact admin for approval.'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver - Route ${_routeNumber ?? ''}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Name: ${_driverData?['name'] ?? ''}'),
                subtitle: Text('Phone: ${_driverData?['phone'] ?? ''}'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate Attendance QR'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DriverLiveLocationScreen())),
              icon: const Icon(Icons.location_on),
              label: const Text('Share Live Location'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }
}