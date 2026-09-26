import 'package:flutter/material.dart';

import '../core/database.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _routes =
            data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Routes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _routes.length,
              itemBuilder: (ctx, i) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: ExpansionTile(
                  leading: const Icon(Icons.directions_bus, color: Colors.blue),
                  title: Text(_routes[i]['name']),
                  subtitle: Text('⏰ ${_routes[i]['timing']}'),
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('🛑 Stops: ${_routes[i]['stops']}',
                            style: const TextStyle(fontSize: 14)))
                  ],
                ),
              ),
            ),
    );
  }
}