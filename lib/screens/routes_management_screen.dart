import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/empty_state.dart';

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
    try {
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
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEditRoute({Map<String, dynamic>? existing}) async {
    final routeNumCtrl =
        TextEditingController(text: existing?['routeNumber']);
    final nameCtrl = TextEditingController(text: existing?['name']);
    final stopsCtrl = TextEditingController(text: existing?['stops']);
    final timingCtrl = TextEditingController(text: existing?['timing']);
    final driverCtrl = TextEditingController(text: existing?['driverName']);
    final assistantCtrl =
        TextEditingController(text: existing?['assistantName']);
    final conductorCtrl =
        TextEditingController(text: existing?['conductorName']);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Route' : 'Edit Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: routeNumCtrl,
                decoration: const InputDecoration(
                    labelText: 'Route Number (e.g., 1)'),
              ),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Route Name')),
              TextField(
                  controller: stopsCtrl,
                  decoration: const InputDecoration(labelText: 'Stops')),
              TextField(
                  controller: timingCtrl,
                  decoration: const InputDecoration(labelText: 'Timing')),
              const Divider(),
              const Text('Staff Details',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                  controller: driverCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Driver Name')),
              TextField(
                  controller: assistantCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Assistant Driver Name')),
              TextField(
                  controller: conductorCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Conductor Name')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
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
        'timing': timingCtrl.text.trim(),
        'driverName': driverCtrl.text.trim(),
        'assistantName': assistantCtrl.text.trim(),
        'conductorName': conductorCtrl.text.trim(),
      };
      try {
        if (existing != null) {
          await getDatabase().ref('routes/${existing['id']}').update(data);
          CustomSnackbar.success(context, 'Route updated!');
        } else {
          await getDatabase().ref('routes').push().set(data);
          CustomSnackbar.success(context, 'Route added!');
        }
        _loadRoutes();
      } catch (e) {
        CustomSnackbar.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _deleteRoute(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Route?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await getDatabase().ref('routes/$id').remove();
      CustomSnackbar.success(context, 'Route deleted');
      _loadRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _addEditRoute(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No routes yet',
                  subtitle: 'Tap + to add your first route',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _routes.length,
                  itemBuilder: (ctx, i) {
                    final route = _routes[i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.route_rounded,
                              color: AppColors.primary),
                        ),
                        title: Text(
                          'Route ${route['routeNumber']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          route['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow('Stops', route['stops']),
                                _infoRow('Timing', route['timing']),
                                _infoRow('Driver', route['driverName']),
                                _infoRow('Assistant', route['assistantName']),
                                _infoRow('Conductor', route['conductorName']),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _addEditRoute(existing: route),
                                      icon: const Icon(Icons.edit_rounded,
                                          size: 16),
                                      label: const Text('Edit'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _deleteRoute(route['id']),
                                      icon: const Icon(Icons.delete_rounded,
                                          size: 16),
                                      label: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
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

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}