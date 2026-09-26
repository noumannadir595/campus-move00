import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';

class SOSAlertsScreen extends StatefulWidget {
  const SOSAlertsScreen({super.key});
  @override
  State<SOSAlertsScreen> createState() => _SOSAlertsScreenState();
}

class _SOSAlertsScreenState extends State<SOSAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final snap =
        await getDatabase().ref('sosAlerts').orderByChild('timestamp').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _alerts = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _alerts.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _resolveAlert(String id) async {
    await getDatabase().ref('sosAlerts/$id').update({'status': 'resolved'});
    _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (ctx, i) {
                final alert = _alerts[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  color: alert['status'] == 'active'
                      ? Colors.red.shade50
                      : Colors.grey.shade200,
                  child: ListTile(
                    title: Text(alert['userName']),
                    subtitle: Text(
                        'Time: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(alert['timestamp']))}\nStatus: ${alert['status']}'),
                    trailing: alert['status'] == 'active'
                        ? ElevatedButton(
                            onPressed: () => _resolveAlert(alert['id']),
                            child: const Text('Resolve'))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}