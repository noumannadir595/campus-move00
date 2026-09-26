import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());
      final user = FirebaseAuth.instance.currentUser!;
      final snapshot = await getDatabase().ref('users/${user.uid}').get();
      if (snapshot.exists && (snapshot.value as Map)['role'] == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminDashboardWrapper()));
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not authorized')));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Login failed')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Admin Login'),
          backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 60, color: Colors.blue),
                  const Text('Admin Access',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  TextField(
                      controller: _emailController,
                      decoration:
                          _inputDecoration('Admin Email', Icons.email)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _inputDecoration('Password', Icons.lock)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login as Admin',
                              style: TextStyle(fontSize: 18))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
}