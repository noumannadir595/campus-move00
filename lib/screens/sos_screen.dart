import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/database.dart';
import '../core/notifications.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});
  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _sending = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await getDatabase().ref('users/${user.uid}').get();
      if (snap.exists && mounted) {
        setState(
            () => _userName = (snap.value as Map)['name'] ?? 'Student');
      }
    }
  }

  Future<void> _sendSOS() async {
    if (_sending) return;
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')));
      setState(() => _sending = false);
      return;
    }
    try {
      await getDatabase().ref('sosAlerts').push().set({
        'userId': user.uid,
        'userName': _userName,
        'timestamp': ServerValue.timestamp,
        'status': 'active'
      });
      const String topic = 'campus_move_emergency_123';
      final url = Uri.parse('https://ntfy.sh/$topic');
      final response = await http.post(url,
          body:
              'EMERGENCY SOS - Campus Move\n\nStudent Name: $_userName\nTime: ${DateTime.now()}\nPlease call immediately.');
      if (response.statusCode == 200) {
        showReminder('SOS Sent',
            'Emergency alert sent to guardian & admin.');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('SOS sent! Guardian notified.')));
      } else {
        throw Exception('Ntfy error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.warning, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text('Tap button to send emergency alert',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text('Notifying: campus_move_emergency_123',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
              onPressed: _sending ? null : _sendSOS,
              icon: const Icon(Icons.sos, size: 30),
              label: const Text('SEND SOS', style: TextStyle(fontSize: 24)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)))),
          if (_sending)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator()),
        ]),
      ),
    );
  }
}