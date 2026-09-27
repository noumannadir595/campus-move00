import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/database.dart';
import '../theme.dart';
import 'driver_live_location_screen.dart';
import 'auth_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Map<String, dynamic>? _driverData;
  bool _loading = true;
  String? _routeNumber;
  String? _routeName;

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
        await _loadRouteDetails();
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
            await _loadRouteDetails();
            return;
          }
        }
      }

      setState(() {
        _driverData = null;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _driverData = null;
      });
    }
  }

  Future<void> _loadRouteDetails() async {
    if (_driverData == null) return;
    final routeId = _driverData?['assignedRoute'] ?? _driverData?['routeId'];
    if (routeId == null) return;
    final snap = await getDatabase().ref('routes/$routeId').get();
    if (snap.exists) {
      final r = snap.value as Map;
      setState(() {
        _routeNumber = r['routeNumber']?.toString() ?? '';
        _routeName = r['name']?.toString() ?? '';
      });
    }
  }

  void _generateQR() {
    if (_driverData == null) return;
    final routeId = _driverData?['assignedRoute'] ?? _driverData?['routeId'];
    if (routeId == null) return;

    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final qrData =
        'CAMPUS_MOVE_ATTENDANCE|$sessionId|$routeId|${DateTime.now().toIso8601String()}';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attendance QR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Route ${_routeNumber ?? ''}: ${_routeName ?? ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: QrImageView(data: qrData, size: 200),
              ),
              const SizedBox(height: 12),
              const Text(
                'Valid for 1 hour',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
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
              Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Application pending or rejected'),
              Text('Please contact admin'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primaryLight.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _driverData?['name'] ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _driverData?['phone'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_routeName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Route $_routeNumber: $_routeName',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // QR Button
            _actionCard(
              icon: Icons.qr_code_rounded,
              title: 'Generate Attendance QR',
              subtitle: 'Students will scan to mark attendance',
              color: AppColors.primary,
              onTap: _generateQR,
            ),
            const SizedBox(height: 12),

            // Live Location Button
            _actionCard(
              icon: Icons.location_on_rounded,
              title: 'Share Live Location',
              subtitle: 'Let students track your bus',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverLiveLocationScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}