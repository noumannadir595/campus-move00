import 'package:firebase_database/firebase_database.dart';
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
        final list = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        list.sort((a, b) {
          final aNum =
              int.tryParse(a['routeNumber']?.toString() ?? '') ?? 999;
          final bNum =
              int.tryParse(b['routeNumber']?.toString() ?? '') ?? 999;
          return aNum.compareTo(bNum);
        });
        if (mounted) {
          setState(() {
            _routes = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== ADD / EDIT ====================
  Future<void> _addEdit({Map<String, dynamic>? existing}) async {
    final routeNumCtrl =
        TextEditingController(text: existing?['routeNumber']?.toString() ?? '');
    final nameCtrl =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final stopsCtrl =
        TextEditingController(text: existing?['stops']?.toString() ?? '');
    final timingCtrl =
        TextEditingController(text: existing?['timing']?.toString() ?? '');
    final startLatCtrl =
        TextEditingController(text: existing?['startLat']?.toString() ?? '');
    final startLngCtrl =
        TextEditingController(text: existing?['startLng']?.toString() ?? '');
    final endLatCtrl =
        TextEditingController(text: existing?['endLat']?.toString() ?? '');
    final endLngCtrl =
        TextEditingController(text: existing?['endLng']?.toString() ?? '');
    final driverNameCtrl =
        TextEditingController(text: existing?['driverName']?.toString() ?? '');
    final conductorNameCtrl = TextEditingController(
        text: existing?['conductorName']?.toString() ?? '');

    // ✅ NAYA: Driver Phone
    final driverPhoneCtrl =
        TextEditingController(text: existing?['driverPhone']?.toString() ?? '');

    // ✅ NAYA: Conductor Phone
    final conductorPhoneCtrl = TextEditingController(
        text: existing?['conductorPhone']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              existing == null ? Icons.add_circle : Icons.edit,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(existing == null ? 'Add Route' : 'Edit Route'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================== BASIC INFO ====================
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Basic Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: routeNumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Route Number',
                    hintText: 'e.g., 1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Route Name',
                    hintText: 'e.g., Route 1: CUI - Sahiwal',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: stopsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Stops',
                    hintText: 'e.g., CUI, Stop A, Sahiwal',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Timing',
                    hintText: 'e.g., 8:00 AM - 10:00 AM',
                  ),
                ),

                // ==================== COORDINATES ====================
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Starting Point (CUI)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Get from Google Maps (right-click location)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startLatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Start Latitude',
                    hintText: 'e.g., 31.4479',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: startLngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Start Longitude',
                    hintText: 'e.g., 74.5299',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),

                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ending Point',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endLatCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'End Latitude',
                    hintText: 'e.g., 30.6682',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: endLngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'End Longitude',
                    hintText: 'e.g., 73.1114',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),

                // ==================== STAFF ====================
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Staff Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: driverNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                  ),
                ),
                const SizedBox(height: 10),
                // ✅ NAYA: Driver Phone
                TextField(
                  controller: driverPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Driver Phone',
                    hintText: 'e.g., 0300-1234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: conductorNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conductor Name',
                  ),
                ),
                const SizedBox(height: 10),
                // ✅ NAYA: Conductor Phone
                TextField(
                  controller: conductorPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Conductor Phone',
                    hintText: 'e.g., 0300-1234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Validation
    if (routeNumCtrl.text.trim().isEmpty ||
        nameCtrl.text.trim().isEmpty ||
        startLatCtrl.text.trim().isEmpty ||
        startLngCtrl.text.trim().isEmpty ||
        endLatCtrl.text.trim().isEmpty ||
        endLngCtrl.text.trim().isEmpty) {
      if (!mounted) return;
      CustomSnackbar.warning(
          context, 'Fill route number, name and all coordinates');
      return;
    }

    final startLat = double.tryParse(startLatCtrl.text.trim());
    final startLng = double.tryParse(startLngCtrl.text.trim());
    final endLat = double.tryParse(endLatCtrl.text.trim());
    final endLng = double.tryParse(endLngCtrl.text.trim());

    if (startLat == null ||
        startLng == null ||
        endLat == null ||
        endLng == null) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Invalid coordinates format');
      return;
    }

    try {
      final data = {
        'routeNumber': routeNumCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'stops': stopsCtrl.text.trim(),
        'timing': timingCtrl.text.trim(),
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'driverName': driverNameCtrl.text.trim(),
        'driverPhone': driverPhoneCtrl.text.trim(),      // ✅ NAYA
        'conductorName': conductorNameCtrl.text.trim(),
        'conductorPhone': conductorPhoneCtrl.text.trim(), // ✅ NAYA
        'updatedAt': ServerValue.timestamp,
      };

      if (existing != null) {
        await getDatabase().ref('routes/${existing['id']}').update(data);
        if (!mounted) return;
        CustomSnackbar.success(context, 'Route updated!');
      } else {
        await getDatabase().ref('routes').push().set({
          ...data,
          'createdAt': ServerValue.timestamp,
        });
        if (!mounted) return;
        CustomSnackbar.success(context, 'Route added!');
      }
      _loadRoutes();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  // ==================== DELETE ====================
  Future<void> _delete(String id, String routeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Route?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$routeName"?'),
            const SizedBox(height: 10),
            const Text(
              'This will also remove any live bus location for this route.',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await getDatabase().ref('routes/$id').remove();
      await getDatabase().ref('busLocations/$id').remove();

      if (!mounted) return;
      CustomSnackbar.success(context, 'Route deleted!');
      _loadRoutes();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRoutes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEdit(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Route'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? const EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No routes yet',
                  subtitle: 'Tap "Add Route" to create one',
                )
              : RefreshIndicator(
                  onRefresh: _loadRoutes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _routes.length,
                    itemBuilder: (ctx, i) => _buildRouteCard(_routes[i]),
                  ),
                ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final hasCoords = route['startLat'] != null &&
        route['startLng'] != null &&
        route['endLat'] != null &&
        route['endLng'] != null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.route,
                          color: Colors.white, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        route['routeNumber']?.toString() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['name']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route['timing']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasCoords)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'TRACK',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (route['stops'] != null &&
                route['stops'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route['stops'].toString(),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ✅ NAYA: Driver aur Conductor info
            if (route['driverName'] != null &&
                route['driverName'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Driver: ${route['driverName']}${route['driverPhone'] != null && route['driverPhone'].toString().isNotEmpty ? ' • ${route['driverPhone']}' : ''}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (route['conductorName'] != null &&
                route['conductorName'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Conductor: ${route['conductorName']}${route['conductorPhone'] != null && route['conductorPhone'].toString().isNotEmpty ? ' • ${route['conductorPhone']}' : ''}',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(
                        route['id'], route['name']?.toString() ?? 'Route'),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addEdit(existing: route),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}