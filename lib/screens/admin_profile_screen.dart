import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _newPasswordController = TextEditingController();
  Map<String, dynamic>? _userData;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await getDatabase().ref('users/${user.uid}').get();
    if (snapshot.exists && mounted) {
      setState(
          () => _userData = Map<String, dynamic>.from(snapshot.value as Map));
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) return;
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated')));
      }
      _newPasswordController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const CircleAvatar(
              radius: 50,
              child: Icon(Icons.admin_panel_settings, size: 50)),
          const SizedBox(height: 20),
          Text('Name: ${_userData!['name']}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          const Text('Role: Admin',
              style: TextStyle(fontSize: 16, color: Colors.blue)),
          const Divider(height: 40),
          TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _updatePassword,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Update Password')),
        ]),
      ),
    );
  }
}