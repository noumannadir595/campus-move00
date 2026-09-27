import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/database.dart';
import '../core/notifications.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isScanning = false;
  bool _marked = false;
  String _result = '';
  String? _routeName;
  final MobileScannerController scannerController = MobileScannerController();

  Future<bool> _checkPaymentStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();
      if (snap.exists && snap.value != null) {
        final data = snap.value as Map<dynamic, dynamic>;
        if (data.isNotEmpty) {
          final app = data.values.first;
          if (app['paymentStatus'] == 'paid') return true;
        }
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanning || _marked) return;

    final isPaid = await _checkPaymentStatus();
    if (!isPaid) {
      if (mounted) {
        setState(() {
          _result = 'Please complete fee payment first';
        });
        CustomSnackbar.warning(
            context, 'Please complete fee payment first');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _result = '');
        });
      }
      return;
    }

    final String? code = capture.barcodes.first.rawValue;
    if (code == null || !code.startsWith('CAMPUS_MOVE_ATTENDANCE|')) return;

    setState(() {
      _isScanning = true;
      _result = 'Processing...';
    });

    final parts = code.split('|');
    if (parts.length < 4) {
      setState(() {
        _isScanning = false;
        _result = 'Invalid QR code';
      });
      CustomSnackbar.error(context, 'Invalid QR code');
      return;
    }

    final sessionId = parts[1];
    final routeId = parts[2];

    try {
      final sessionSnap =
          await getDatabase().ref('attendanceSessions/$sessionId').get();

      if (!sessionSnap.exists) {
        setState(() {
          _isScanning = false;
          _result = 'QR code expired or invalid';
        });
        CustomSnackbar.error(context, 'QR code expired or invalid');
        return;
      }

      final expiryMap = sessionSnap.value as Map<dynamic, dynamic>;
      final expiry = (expiryMap['expiry'] ?? 0) as int;

      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        setState(() {
          _isScanning = false;
          _result = 'QR code has expired';
        });
        CustomSnackbar.error(context, 'QR code has expired');
        return;
      }

      final user = FirebaseAuth.instance.currentUser!;
      final userSnap = await getDatabase().ref('users/${user.uid}').get();
      final studentName =
          (userSnap.value as Map<dynamic, dynamic>)['name'] as String? ??
              'Student';

      // Get route name
      String routeName = routeId;
      final routeSnap = await getDatabase().ref('routes/$routeId').get();
      if (routeSnap.exists) {
        final r = routeSnap.value as Map<dynamic, dynamic>;
        routeName = 'Route ${r['routeNumber']}: ${r['name']}';
      }

      // Check if already marked today
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final existing = await getDatabase()
          .ref('attendance')
          .orderByChild('studentId')
          .equalTo(user.uid)
          .get();

      if (existing.exists) {
        final records = existing.value as Map<dynamic, dynamic>;
        for (var record in records.values) {
          final recDate =
              (record['date'] ?? '').toString().substring(0, 10);
          if (recDate == today && record['route'] == routeId) {
            setState(() {
              _isScanning = false;
              _result = 'Attendance already marked today';
            });
            CustomSnackbar.info(
                context, 'Attendance already marked today');
            return;
          }
        }
      }

      // Save attendance
      await getDatabase().ref('attendance').push().set({
        'studentId': user.uid,
        'studentName': studentName,
        'route': routeId,
        'timestamp': ServerValue.timestamp,
        'date': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _marked = true;
        _result = 'Attendance marked!';
        _routeName = routeName;
      });

      showReminder('Attendance Marked', 'You marked attendance for $routeName');
      CustomSnackbar.success(context, 'Attendance marked successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _result = 'Error: $e';
      });
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  void _resetScanner() {
    setState(() {
      _marked = false;
      _result = '';
      _routeName = null;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _marked
          ? _buildSuccessView()
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: scannerController,
                        onDetect: _onDetect,
                      ),
                      // Overlay
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.8),
                            width: 4,
                          ),
                        ),
                      ),
                      // Scan frame
                      Center(
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isScanning) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        Icon(
                          _result.isEmpty
                              ? Icons.qr_code_scanner_rounded
                              : (_result.contains('Error') ||
                                      _result.contains('Invalid') ||
                                      _result.contains('expired') ||
                                      _result.contains('already'))
                                  ? Icons.error_outline_rounded
                                  : Icons.qr_code_scanner_rounded,
                          size: 40,
                          color: _result.isEmpty
                              ? AppColors.primary
                              : Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _result.isEmpty
                              ? 'Point camera at driver\'s QR code'
                              : _result,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 90,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Attendance Marked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            if (_routeName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _routeName!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              DateTime.now().toString().substring(0, 16),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}