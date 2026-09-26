import 'package:flutter/material.dart';

import '../core/database.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final snap = await getDatabase().ref('emergencyContacts').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _contacts =
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
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _contacts.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.contact_emergency, color: Colors.red),
                  title: Text(_contacts[i]['name']),
                  subtitle: Text(_contacts[i]['number']),
                  trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.blue),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Calling ${_contacts[i]['number']}...')));
                      }),
                ),
              ),
            ),
    );
  }
}