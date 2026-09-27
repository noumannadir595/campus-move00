import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.isLoginDefault = true});
  final bool isLoginDefault;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLoginMode;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _regIdCtrl = TextEditingController();

  String _userType = 'student';
  String _passwordStrength = '';
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.isLoginDefault;
    _passCtrl.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _regIdCtrl.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final pass = _passCtrl.text;
    if (pass.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _strengthColor = Colors.grey;
      });
      return;
    }

    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 10) score++;
    if (pass.contains(RegExp(r'[A-Z]'))) score++;
    if (pass.contains(RegExp(r'[0-9]'))) score++;
    if (pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
      if (score <= 2) {
        _passwordStrength = 'Weak';
        _strengthColor = Colors.red;
      } else if (score <= 4) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = Colors.green;
      }
    });
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;
      CustomSnackbar.success(context, 'Login successful!');

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address';
      } else if (e.code == 'network-request-failed') {
        msg = 'No internet connection';
      }
      CustomSnackbar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _deptCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please fill all fields');
      return;
    }

    if (_userType == 'student' && _regIdCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter registration number');
      return;
    }

    if (_userType == 'faculty' && _regIdCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter university ID');
      return;
    }

    if (_passwordStrength == 'Weak') {
      CustomSnackbar.warning(
          context, 'Password is too weak. Use uppercase, numbers, symbols');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final role = _emailCtrl.text.trim() == 'admin@campusmove.com'
          ? 'admin'
          : 'user';

      final Map<String, dynamic> userData = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'userType': _userType,
        'role': role,
        'department': _deptCtrl.text.trim(),
        'createdAt': ServerValue.timestamp,
      };

      if (_userType == 'student') {
        userData['registrationNumber'] = _regIdCtrl.text.trim();
      } else {
        userData['universityId'] = _regIdCtrl.text.trim();
      }

      await getDatabase().ref('users/${cred.user!.uid}').set(userData);

      if (!mounted) return;
      CustomSnackbar.success(context, 'Account created successfully!');

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already registered';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak';
      } else if (e.code == 'network-request-failed') {
        msg = 'No internet connection';
      } else {
        msg = e.message ?? 'Signup failed';
      }
      CustomSnackbar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter your email first');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      CustomSnackbar.success(context, 'Password reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, e.message ?? 'Failed to send reset email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Sign Up'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoginMode ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginMode
                        ? 'Login to continue'
                        : 'Sign up to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (!_isLoginMode) ...[
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                          ],

                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscurePassword,
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
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            textInputAction: TextInputAction.next,
                          ),

                          if (!_isLoginMode && _passwordStrength.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const SizedBox(width: 4),
                                Icon(Icons.lock,
                                    size: 14, color: _strengthColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Strength: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _passwordStrength,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _strengthColor,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (_isLoginMode) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _forgotPassword,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                          ],

                          if (!_isLoginMode) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _deptCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _userType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'student',
                                  child: Text('Student'),
                                ),
                                DropdownMenuItem(
                                  value: 'faculty',
                                  child: Text('Faculty'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _userType = val);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'I am a',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _regIdCtrl,
                              decoration: InputDecoration(
                                labelText: _userType == 'student'
                                    ? 'Registration Number'
                                    : 'University ID',
                                prefixIcon: const Icon(Icons.badge_outlined),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          LoadingButton(
                            label: _isLoginMode ? 'Login' : 'Sign Up',
                            isLoading: _isLoading,
                            icon: _isLoginMode
                                ? Icons.login_rounded
                                : Icons.person_add_rounded,
                            onPressed: _isLoginMode ? _login : _signup,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _nameCtrl.clear();
                        _emailCtrl.clear();
                        _passCtrl.clear();
                        _phoneCtrl.clear();
                        _deptCtrl.clear();
                        _regIdCtrl.clear();
                        _passwordStrength = '';
                      });
                    },
                    child: Text(
                      _isLoginMode
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Login",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // ==================== DRIVER REGISTER LINK ====================
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/driver-signup');
                    },
                    icon: const Icon(Icons.drive_eta, size: 18),
                    label: const Text(
                      'Register as Driver',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}