import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/database.dart';
import '../core/notifications.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends State<StudentAttendanceScreen> {
  bool _isScanning = false;
  String _result = '';
  final MobileScannerController scannerController = MobileScannerController();

  Future<bool> _checkPaymentStatus() async {
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
    return false;
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanning) return;
    final isPaid = await _checkPaymentStatus();
    if (!isPaid) {
      if (mounted) {
        setState(() =>
            _result = '⚠️ Please complete fee payment first to mark attendance.');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _result = '');
        });
      }
      return;
    }
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.startsWith('CAMPUS_MOVE_ATTENDANCE|')) {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _result = 'Processing...';
        });
      }
      final parts = code.split('|');
      if (parts.length >= 4) {
        final sessionId = parts[1];
        final route = parts[2];
        final sessionSnap =
            await getDatabase().ref('attendanceSessions/$sessionId').get();
        if (!sessionSnap.exists) {
          _result = 'Invalid or expired QR code.';
        } else {
          final expiryMap = sessionSnap.value as Map<dynamic, dynamic>;
          if (DateTime.now().millisecondsSinceEpoch >
              (expiryMap['expiry'] as int)) {
            _result = 'QR code expired.';
          } else {
            final user = FirebaseAuth.instance.currentUser!;
            final userSnap =
                await getDatabase().ref('users/${user.uid}').get();
            final studentName =
                (userSnap.value as Map<dynamic, dynamic>)['name'] as String;
            await getDatabase().ref('attendance').push().set({
              'studentId': user.uid,
              'studentName': studentName,
              'route': route,
              'timestamp': ServerValue.timestamp,
              'date': DateTime.now().toIso8601String()
            });
            _result = 'Attendance marked for route $route!';
            showReminder(
                'Attendance Marked', 'You have marked attendance for $route');
          }
        }
      } else {
        _result = 'Invalid QR code.';
      }
      if (mounted) {
        setState(() => _isScanning = false);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _result = '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(children: [
        Expanded(
            flex: 3,
            child: MobileScanner(
                controller: scannerController, onDetect: _onDetect)),
        Expanded(
            child: Center(
                child: Text(_result,
                    style: const TextStyle(fontSize: 16)))),
      ]),
    );
  }
}