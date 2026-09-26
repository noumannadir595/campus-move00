import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _regIdCtrl = TextEditingController();
  String _userType = 'student';
  bool _isLoading = false;

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (value.length < 10) {
      return 'Invalid phone';
    }
    return null;
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _deptCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    if (_userType == 'student' && _regIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration number required')));
      return;
    }

    if (_userType == 'faculty' && _regIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('University ID required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final role =
          _emailCtrl.text.trim() == 'admin@campusmove.com' ? 'admin' : 'user';

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
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Sign Up'), backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Text('Create Account',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _nameCtrl,
                      decoration:
                          _inputDecoration('Full Name', Icons.person)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _emailCtrl,
                      decoration: _inputDecoration('Email', Icons.email)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration:
                          _inputDecoration('Password', Icons.lock)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _phoneCtrl,
                      decoration: _inputDecoration(
                          'Phone Number', Icons.phone),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _deptCtrl,
                      decoration: _inputDecoration(
                          'Department', Icons.business)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _userType,
                    items: const [
                      DropdownMenuItem<String>(
                          value: 'student', child: Text('Student')),
                      DropdownMenuItem<String>(
                          value: 'faculty', child: Text('Faculty')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _userType = val);
                      }
                    },
                    decoration:
                        _inputDecoration('I am a', Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _regIdCtrl,
                      decoration: _inputDecoration(
                          _userType == 'student'
                              ? 'Registration Number'
                              : 'University ID',
                          Icons.badge)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign Up',
                              style: TextStyle(fontSize: 18))),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                          'Already have an account? Login')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}