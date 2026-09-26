import 'package:flutter/material.dart';

import '../core/database.dart';

class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});
  @override
  State<RoutesManagementScreen> createState() =>
      _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    final snapshot = await getDatabase().ref('routes').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _routes = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEditRoute({Map<String, dynamic>? existing}) async {
    final routeNumCtrl =
        TextEditingController(text: existing?['routeNumber']);
    final nameCtrl = TextEditingController(text: existing?['name']);
    final stopsCtrl = TextEditingController(text: existing?['stops']);
    final driverCtrl = TextEditingController(text: existing?['driverName']);
    final assistantCtrl =
        TextEditingController(text: existing?['assistantName']);
    final conductorCtrl =
        TextEditingController(text: existing?['conductorName']);
    final driverPhoneCtrl =
        TextEditingController(text: existing?['driverPhone']);
    final assistantPhoneCtrl =
        TextEditingController(text: existing?['assistantPhone']);
    final conductorPhoneCtrl =
        TextEditingController(text: existing?['conductorPhone']);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Route' : 'Edit Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: routeNumCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Route Number (e.g., 1)')),
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Route Name')),
              TextField(
                  controller: stopsCtrl,
                  decoration: const InputDecoration(labelText: 'Stops')),
              const Divider(),
              const Text('Staff Details',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: driverCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Driver Name')),
              TextField(
                  controller: driverPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Driver Phone')),
              TextField(
                  controller: assistantCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Assistant Driver Name')),
              TextField(
                  controller: assistantPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Assistant Phone')),
              TextField(
                  controller: conductorCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conductor Name')),
              TextField(
                  controller: conductorPhoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conductor Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final data = {
        'routeNumber': routeNumCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'stops': stopsCtrl.text.trim(),
        'driverName': driverCtrl.text.trim(),
        'driverPhone': driverPhoneCtrl.text.trim(),
        'assistantName': assistantCtrl.text.trim(),
        'assistantPhone': assistantPhoneCtrl.text.trim(),
        'conductorName': conductorCtrl.text.trim(),
        'conductorPhone': conductorPhoneCtrl.text.trim(),
      };
      if (existing != null) {
        await getDatabase().ref('routes/${existing['id']}').update(data);
      } else {
        await getDatabase().ref('routes').push().set(data);
      }
      _loadRoutes();
    }
  }

  Future<void> _deleteRoute(String id) async {
    await getDatabase().ref('routes/$id').remove();
    _loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [
          IconButton(
              icon: const Icon(Icons.add), onPressed: () => _addEditRoute())
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (ctx, i) {
                final route = _routes[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(
                        'Route ${route['routeNumber']}: ${route['name']}'),
                    subtitle: Text('Driver: ${route['driverName']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stops: ${route['stops']}'),
                            const Divider(),
                            Text(
                                'Driver: ${route['driverName']} (${route['driverPhone']})'),
                            Text(
                                'Assistant: ${route['assistantName']} (${route['assistantPhone']})'),
                            Text(
                                'Conductor: ${route['conductorName']} (${route['conductorPhone']})'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _addEditRoute(existing: route)),
                                IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _deleteRoute(route['id'])),
                              ],
                            ),
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