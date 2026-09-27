import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';
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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _isRouteTaken(String routeId) async {
    try {
      final usersSnap = await getDatabase()
          .ref('users')
          .orderByChild('assignedRoute')
          .equalTo(routeId)
          .get();
      if (usersSnap.exists) return true;

      final appsSnap = await getDatabase()
          .ref('driverApplications')
          .orderByChild('routeId')
          .equalTo(routeId)
          .get();
      if (appsSnap.exists) {
        final apps = appsSnap.value as Map<dynamic, dynamic>;
        for (var app in apps.values) {
          if (app['status'] == 'pending' || app['status'] == 'approved') {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _selectedRouteId.isEmpty) {
      CustomSnackbar.warning(context, 'Please fill all fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final taken = await _isRouteTaken(_selectedRouteId);
      if (taken) {
        if (mounted) {
          CustomSnackbar.error(
              context, 'This route already has a driver registered');
          setState(() => _isSubmitting = false);
        }
        return;
      }

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
      CustomSnackbar.success(
          context, 'Application submitted! Wait for admin approval.');
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _selectedRouteId = '');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        msg = 'Email already registered';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak';
      }
      CustomSnackbar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter email and password');
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
              if (mounted) {
                CustomSnackbar.warning(context,
                    'Your application is still pending approval');
              }
              setState(() => _isSubmitting = false);
              return;
            }
          }
        }
      }

      if (isDriver) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          CustomSnackbar.error(context, 'No driver account found');
        }
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Login failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==================== OVERFLOW FIX ====================
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(_isLoginMode ? 'Driver Login' : 'Driver Registration'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),

                    // Header icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.drive_eta_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      _isLoginMode ? 'Driver Login' : 'Join as Driver',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoginMode
                          ? 'Login to access your dashboard'
                          : 'Register to start driving',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Name (signup only)
                            if (!_isLoginMode) ...[
                              TextField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedRouteId.isEmpty
                                    ? null
                                    : _selectedRouteId,
                                hint: const Text('Select Route'),
                                isExpanded: true,
                                items: _routes.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: r['id'] as String,
                                    child: Text(
                                      'Route ${r['routeNumber']}: ${r['name']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedRouteId = v!),
                                decoration: const InputDecoration(
                                  labelText: 'Route',
                                  prefixIcon: Icon(Icons.route_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Email
                            TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextField(
                              controller: _passCtrl,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit button
                            LoadingButton(
                              label: _isLoginMode
                                  ? 'Login'
                                  : 'Submit Application',
                              isLoading: _isSubmitting,
                              onPressed: _isLoginMode ? _login : _signup,
                              icon: _isLoginMode
                                  ? Icons.login_rounded
                                  : Icons.person_add_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle login/signup
                    TextButton(
                      onPressed: () => setState(() {
                        _isLoginMode = !_isLoginMode;
                        _nameCtrl.clear();
                        _phoneCtrl.clear();
                        _selectedRouteId = '';
                        _emailCtrl.clear();
                        _passCtrl.clear();
                      }),
                      child: Text(
                        _isLoginMode
                            ? "Don't have an account? Register"
                            : "Already registered? Login",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}