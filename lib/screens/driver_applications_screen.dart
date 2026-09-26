import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../core/notifications.dart';

class DriverApplicationsScreen extends StatefulWidget {
  const DriverApplicationsScreen({super.key});
  @override
  State<DriverApplicationsScreen> createState() =>
      _DriverApplicationsScreenState();
}

class _DriverApplicationsScreenState
    extends State<DriverApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final snap = await getDatabase()
        .ref('driverApplications')
        .orderByChild('status')
        .equalTo('pending')
        .get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _applications = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String appId, String userId, String routeId,
      String name, String email, String phone) async {
    await getDatabase()
        .ref('driverApplications/$appId')
        .update({'status': 'approved'});

    // Generate unique busId automatically
    final busId = 'bus_${DateTime.now().millisecondsSinceEpoch}';

    final userData = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'driver',
      'userType': 'driver',
      'assignedRoute': routeId,
      'busId': busId,
      'createdAt': ServerValue.timestamp,
    };
    await getDatabase().ref('users/$userId').set(userData);
    showReminder('Driver Application Approved',
        'Your driver application has been approved. You can now login.');
    _loadApplications();
  }

  Future<void> _reject(String appId) async {
    await getDatabase()
        .ref('driverApplications/$appId')
        .update({'status': 'rejected'});
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Applications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No pending driver applications'))
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (ctx, i) {
                    final app = _applications[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(app['name']),
                        subtitle: Text(
                            'Email: ${app['email']}\nPhone: ${app['phone']}\nRoute ID: ${app['routeId']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _approve(
                                    app['id'],
                                    app['userId'],
                                    app['routeId'],
                                    app['name'],
                                    app['email'],
                                    app['phone'])),
                            IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: () => _reject(app['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}