import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'driver_signup_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'User not found';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good Morning!';
    if (hour < 16) return '🌸 Good Afternoon!';
    if (hour < 20) return '🌙 Good Evening!';
    return '🌃 Good Night!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Login'), backgroundColor: Colors.transparent),
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
                  const Icon(Icons.directions_bus,
                      size: 60, color: Colors.blue),
                  const Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_getGreeting(),
                      style: const TextStyle(
                          fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 30),
                  TextField(
                      controller: _emailController,
                      decoration:
                          _inputDecoration('Email', Icons.email)),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration:
                          _inputDecoration('Password', Icons.lock)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login',
                              style: TextStyle(fontSize: 18))),
                  TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                      child: const Text(
                          "Don't have an account? Sign Up")),
                  TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DriverSignupScreen())),
                      child: const Text('Register as Driver')),
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