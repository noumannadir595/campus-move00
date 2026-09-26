import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/notifications.dart';

class AllAppsScreen extends StatefulWidget {
  const AllAppsScreen({super.key});
  @override
  State<AllAppsScreen> createState() => _AllAppsScreenState();
}

class _AllAppsScreenState extends State<AllAppsScreen> {
  List<Map<String, dynamic>> _allApps = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadAllApps();
  }

  Future<void> _loadAllApps() async {
    setState(() => _isLoading = true);
    final appsSnap = await getDatabase().ref('applications').get();
    if (appsSnap.exists && mounted) {
      final apps = appsSnap.value as Map<dynamic, dynamic>;
      setState(() {
        _allApps = apps.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPayment(String appKey) async {
    await getDatabase()
        .ref('applications/$appKey')
        .update({'paymentStatus': 'paid'});
    showReminder('Payment Verified',
        'Your payment has been verified. You can now generate your transport card and mark attendance.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verified')));
      _loadAllApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allApps.length,
              itemBuilder: (ctx, i) {
                final app = _allApps[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(app['name']),
                    subtitle: Text(
                        'Status: ${app['status']} | Payment: ${app['paymentStatus'] ?? 'N/A'}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📧 Email: ${app['email']}'),
                            Text('📞 Phone: ${app['phone']}'),
                            Text('🏛 Department: ${app['department']}'),
                            Text('🆔 ID: ${app['regId']}'),
                            Text('🚌 Route: ${app['route']}'),
                            if (app['paymentStatus'] == 'proof_uploaded')
                              ElevatedButton(
                                  onPressed: () =>
                                      _verifyPayment(app['id']),
                                  child: const Text('Verify Payment')),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}