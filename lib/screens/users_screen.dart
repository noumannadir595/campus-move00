import 'package:flutter/material.dart';

import '../core/database.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final usersSnap = await getDatabase().ref('users').get();
    if (usersSnap.exists && mounted) {
      final users = usersSnap.value as Map<dynamic, dynamic>;
      setState(() {
        _users = users.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_users[i]['name']),
                  subtitle: Text(
                      '${_users[i]['email']} | ${_users[i]['userType']} | Role: ${_users[i]['role']}'),
                  isThreeLine: true,
                ),
              ),
            ),
    );
  }
}