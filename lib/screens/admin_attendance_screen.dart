import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('attendance').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _attendanceRecords = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _attendanceRecords.length,
              itemBuilder: (ctx, i) {
                final rec = _attendanceRecords[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Student: ${rec['studentName']}'),
                    subtitle: Text(
                        'Route: ${rec['route']} | Date: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(rec['timestamp']))}'),
                  ),
                );
              },
            ),
    );
  }
}