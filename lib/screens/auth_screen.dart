import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoginMode = false;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Login controllers
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  // Student signup controllers
  final _stuNameCtrl = TextEditingController();
  final _stuEmailCtrl = TextEditingController();
  final _stuPhoneCtrl = TextEditingController();
  final _stuPassCtrl = TextEditingController();
  final _stuConfirmCtrl = TextEditingController();

  // Faculty signup controllers
  final _facNameCtrl = TextEditingController();
  final _facEmailCtrl = TextEditingController();
  final _facPhoneCtrl = TextEditingController();
  final _facPassCtrl = TextEditingController();
  final _facConfirmCtrl = TextEditingController();

  String _stuPasswordStrength = '';
  Color _stuStrengthColor = Colors.grey;
  String _facPasswordStrength = '';
  Color _facStrengthColor = Colors.grey;

  static const String STUDENT_DOMAIN = '@students.cuisahiwal.edu.pk';
  static const String FACULTY_DOMAIN = '@cuisahiwal.edu.pk';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stuPassCtrl.addListener(() => _checkStrength(_stuPassCtrl.text, true));
    _facPassCtrl.addListener(() => _checkStrength(_facPassCtrl.text, false));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _stuNameCtrl.dispose();
    _stuEmailCtrl.dispose();
    _stuPhoneCtrl.dispose();
    _stuPassCtrl.dispose();
    _stuConfirmCtrl.dispose();
    _facNameCtrl.dispose();
    _facEmailCtrl.dispose();
    _facPhoneCtrl.dispose();
    _facPassCtrl.dispose();
    _facConfirmCtrl.dispose();
    super.dispose();
  }

  void _checkStrength(String pass, bool isStudent) {
    if (pass.isEmpty) {
      setState(() {
        if (isStudent) {
          _stuPasswordStrength = '';
          _stuStrengthColor = Colors.grey;
        } else {
          _facPasswordStrength = '';
          _facStrengthColor = Colors.grey;
        }
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
      String strength;
      Color color;
      if (score <= 2) {
        strength = 'Weak';
        color = Colors.red;
      } else if (score <= 4) {
        strength = 'Medium';
        color = Colors.orange;
      } else {
        strength = 'Strong';
        color = Colors.green;
      }
      if (isStudent) {
        _stuPasswordStrength = strength;
        _stuStrengthColor = color;
      } else {
        _facPasswordStrength = strength;
        _facStrengthColor = color;
      }
    });
  }

  // ==================== LOGIN ====================
  Future<void> _login() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPassCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPassCtrl.text.trim(),
      );
      if (!mounted) return;
      CustomSnackbar.success(context, 'Login successful!');
      await Future.delayed(const Duration(milliseconds: 500));
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
      } else if (e.code == 'invalid-credential') {
        msg = 'Invalid email or password';
      }
      CustomSnackbar.error(context, msg);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== SIGNUP ====================
  Future<void> _signup({required bool isStudent}) async {
    final nameCtrl = isStudent ? _stuNameCtrl : _facNameCtrl;
    final emailCtrl = isStudent ? _stuEmailCtrl : _facEmailCtrl;
    final phoneCtrl = isStudent ? _stuPhoneCtrl : _facPhoneCtrl;
    final passCtrl = isStudent ? _stuPassCtrl : _facPassCtrl;
    final confirmCtrl = isStudent ? _stuConfirmCtrl : _facConfirmCtrl;
    final strength = isStudent ? _stuPasswordStrength : _facPasswordStrength;

    // Validation
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty ||
        confirmCtrl.text.isEmpty) {
      CustomSnackbar.warning(context, 'Please fill all fields');
      return;
    }

    final email = emailCtrl.text.trim().toLowerCase();
    final domain = isStudent ? STUDENT_DOMAIN : FACULTY_DOMAIN;

    if (!email.endsWith(domain)) {
      CustomSnackbar.error(
        context,
        'Invalid email! Must end with $domain',
      );
      return;
    }

    if (passCtrl.text != confirmCtrl.text) {
      CustomSnackbar.error(context, 'Passwords do not match');
      return;
    }

    if (passCtrl.text.length < 6) {
      CustomSnackbar.warning(context, 'Password must be at least 6 characters');
      return;
    }

    if (strength == 'Weak') {
      CustomSnackbar.warning(
          context, 'Password too weak. Add uppercase, numbers, symbols');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passCtrl.text.trim(),
      );

      await getDatabase().ref('users/${cred.user!.uid}').set({
        'name': nameCtrl.text.trim(),
        'email': email,
        'phone': phoneCtrl.text.trim(),
        'userType': isStudent ? 'student' : 'faculty',
        'role': 'user',
        'createdAt': ServerValue.timestamp,
      });

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
        msg = 'Invalid email format';
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

  Future<void> _forgotPassword(String email) async {
    if (email.isEmpty) {
      CustomSnackbar.warning(context, 'Enter your email first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      CustomSnackbar.success(context, 'Reset link sent to $email');
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? 'Login' : 'Sign Up'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus,
                      size: 42, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Create Account',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoginMode
                      ? 'Login to continue'
                      : 'Choose your account type below',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // LOGIN MODE
                if (_isLoginMode)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: _loginEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _loginPassCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => _obscurePass = !_obscurePass),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _forgotPassword(_loginEmailCtrl.text),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LoadingButton(
                            label: 'Login',
                            isLoading: _isLoading,
                            icon: Icons.login_rounded,
                            onPressed: _login,
                          ),
                        ],
                      ),
                    ),
                  )
                // SIGNUP MODE
                else
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: [
                          // Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: AppColors.primary,
                              indicatorWeight: 3,
                              labelColor: AppColors.primary,
                              unselectedLabelColor: Colors.grey,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.school_outlined, size: 20),
                                  text: 'Student',
                                ),
                                Tab(
                                  icon: Icon(Icons.work_outline, size: 20),
                                  text: 'Faculty',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 540,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildSignupForm(true),
                                _buildSignupForm(false),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() => _isLoginMode = !_isLoginMode);
                  },
                  child: Text(
                    _isLoginMode
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm(bool isStudent) {
    final nameCtrl = isStudent ? _stuNameCtrl : _facNameCtrl;
    final emailCtrl = isStudent ? _stuEmailCtrl : _facEmailCtrl;
    final phoneCtrl = isStudent ? _stuPhoneCtrl : _facPhoneCtrl;
    final passCtrl = isStudent ? _stuPassCtrl : _facPassCtrl;
    final confirmCtrl = isStudent ? _stuConfirmCtrl : _facConfirmCtrl;
    final strength = isStudent ? _stuPasswordStrength : _facPasswordStrength;
    final strengthColor = isStudent ? _stuStrengthColor : _facStrengthColor;
    final domain = isStudent ? STUDENT_DOMAIN : FACULTY_DOMAIN;
    final obscurePass = isStudent ? _obscurePass : _obscurePass;
    final obscureConfirm = isStudent ? _obscureConfirm : _obscureConfirm;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isStudent
                        ? 'Student email must end with $domain'
                        : 'Faculty email must end with $domain',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: isStudent
                  ? 'FA22-BSE-038@students.cuisahiwal.edu.pk'
                  : 'name@cuisahiwal.edu.pk',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Contact Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: passCtrl,
            obscureText: obscurePass,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),

          if (strength.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 4),
                Icon(Icons.lock, size: 14, color: strengthColor),
                const SizedBox(width: 6),
                Text('Strength: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text(
                  strength,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: strengthColor),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),

          TextField(
            controller: confirmCtrl,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 20),

          LoadingButton(
            label: 'Sign Up as ${isStudent ? 'Student' : 'Faculty'}',
            isLoading: _isLoading,
            icon: Icons.person_add_rounded,
            onPressed: () => _signup(isStudent: isStudent),
          ),
        ],
      ),
    );
  }
}