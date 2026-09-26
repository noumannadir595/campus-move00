import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import 'driver_home_screen.dart';

class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRouteId = '';
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoginMode = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final snap = await getDatabase().ref('routes').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final loadedRoutes = data.entries.map((e) {
          final value = Map<dynamic, dynamic>.from(e.value);
          return {
            'id': e.key.toString(),
            'routeNumber': value['routeNumber']?.toString() ?? '',
            'name': value['name']?.toString() ?? '',
          };
        }).toList();
        if (mounted) {
          setState(() {
            _routes = loadedRoutes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _selectedRouteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await getDatabase().ref('driverApplications').push().set({
        'userId': cred.user!.uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'routeId': _selectedRouteId,
        'status': 'pending',
        'timestamp': ServerValue.timestamp,
      });
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application submitted. Admin will verify.')));
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _selectedRouteId = '');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      bool isDriver = false;

      final userSnap = await getDatabase().ref('users/$uid').get();
      if (userSnap.exists && (userSnap.value as Map)['role'] == 'driver') {
        isDriver = true;
      }
      if (!isDriver) {
        final appSnap = await getDatabase()
            .ref('driverApplications')
            .orderByChild('userId')
            .equalTo(uid)
            .get();
        if (appSnap.exists) {
          final apps = appSnap.value as Map<dynamic, dynamic>;
          if (apps.isNotEmpty) {
            final app = apps.values.first;
            if (app['status'] == 'approved') {
              isDriver = true;
            } else {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Your application is pending approval.')));
              setState(() => _isSubmitting = false);
              return;
            }
          }
        }
      }
      if (isDriver) {
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
        }
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No driver account found. Please register.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              _isLoginMode ? 'Driver Login' : 'Driver Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_isLoginMode) ...[
                    TextField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRouteId.isEmpty
                          ? null
                          : _selectedRouteId,
                      hint: const Text('Select Route'),
                      items: _routes.map<DropdownMenuItem<String>>((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'] as String,
                          child: Text(
                              'Route ${r['routeNumber']}: ${r['name']}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRouteId = v!),
                      decoration: const InputDecoration(labelText: 'Route'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : (_isLoginMode ? _login : _signup),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isLoginMode ? 'Login' : 'Submit Application'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLoginMode = !_isLoginMode;
                      _nameCtrl.clear();
                      _phoneCtrl.clear();
                      _selectedRouteId = '';
                      _emailCtrl.clear();
                      _passCtrl.clear();
                    }),
                    child: Text(_isLoginMode
                        ? "Don't have an account? Register as Driver"
                        : "Already have a driver account? Login"),
                  ),
                ],
              ),
            ),
    );
  }
}