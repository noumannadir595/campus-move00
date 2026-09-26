import 'package:flutter/material.dart';

import '../core/database.dart';

class EmergencyManagementScreen extends StatefulWidget {
  const EmergencyManagementScreen({super.key});
  @override
  State<EmergencyManagementScreen> createState() =>
      _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState
    extends State<EmergencyManagementScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final snapshot = await getDatabase().ref('emergencyContacts').get();
    if (snapshot.exists && mounted) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _contacts = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEditContact({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final numberCtrl = TextEditingController(text: existing?['number']);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name')),
          TextField(
              controller: numberCtrl,
              decoration:
                  const InputDecoration(labelText: 'Phone Number')),
        ]),
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
        'name': nameCtrl.text.trim(),
        'number': numberCtrl.text.trim()
      };
      if (existing != null) {
        await getDatabase()
            .ref('emergencyContacts/${existing['id']}')
            .update(data);
      } else {
        await getDatabase().ref('emergencyContacts').push().set(data);
      }
      _loadContacts();
    }
  }

  Future<void> _deleteContact(String id) async {
    await getDatabase().ref('emergencyContacts/$id').remove();
    _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts'), actions: [
        IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEditContact())
      ]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (ctx, i) {
                final contact = _contacts[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.emergency, color: Colors.red),
                    title: Text(contact['name']),
                    subtitle: Text(contact['number']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _addEditContact(existing: contact)),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteContact(contact['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}