import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      final snap = await getDatabase().ref('routes').get();
      if (snap.exists && mounted) {
        final data = snap.value as Map<dynamic, dynamic>;
        setState(() {
          _routes = data.entries
              .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
              .toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Routes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _loading
          ? ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => const SkeletonCard(),
            )
          : _routes.isEmpty
              ? const EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No routes available',
                  subtitle: 'Please check back later',
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
                          child: const Icon(Icons.directions_bus_rounded,
                              color: AppColors.primary),
                        ),
                        title: Text(
                          'Route ${route['routeNumber'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          route['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row(Icons.timer_outlined, 'Timing',
                                    route['timing']?.toString() ?? 'N/A'),
                                const SizedBox(height: 8),
                                _row(Icons.location_on_outlined, 'Stops',
                                    route['stops']?.toString() ?? 'N/A'),
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

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}