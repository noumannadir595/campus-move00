import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import 'challan_view_screen.dart';

class ApplyTransportScreen extends StatefulWidget {
  const ApplyTransportScreen({super.key});

  @override
  State<ApplyTransportScreen> createState() => _ApplyTransportScreenState();
}

class _ApplyTransportScreenState extends State<ApplyTransportScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _regIdController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRoute = '';
  List<String> _routesList = [];
  bool _hasApplied = false;
  bool _isLoading = true;
  Map<String, dynamic>? _existingApplication;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadUserData(),
      _loadRoutes(),
      _checkExistingApplication(),
    ]);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _regIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await getDatabase().ref('users/$uid').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        _phoneController.text = data['phone']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _departmentController.text = data['department']?.toString() ?? '';
        if (data['userType'] == 'student') {
          _regIdController.text =
              data['registrationNumber']?.toString() ?? '';
        } else {
          _regIdController.text = data['universityId']?.toString() ?? '';
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final snap = await getDatabase().ref('routes').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final routes = data.entries.map((e) {
          final routeData = Map<dynamic, dynamic>.from(e.value);
          return routeData['name']?.toString() ?? '';
        }).toList();
        if (!mounted) return;
        setState(() => _routesList = routes);
      }
    } catch (e) {
      debugPrint('Routes load error: $e');
    }
  }

  Future<void> _checkExistingApplication() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        if (data.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _hasApplied = true;
            _existingApplication =
                Map<String, dynamic>.from(data.values.first);
          });
        }
      }
    } catch (e) {
      debugPrint('Application check error: $e');
    }
  }

  Future<void> _submitApplication() async {
    if (_selectedRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select route')));
      return;
    }
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (!userSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')));
        return;
      }
      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      await getDatabase().ref('applications').push().set({
        'userId': uid,
        'name': userData['name'],
        'userType': userData['userType'],
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'department': _departmentController.text.trim(),
        'regId': _regIdController.text.trim(),
        'route': _selectedRoute,
        'status': 'pending',
        'submittedAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')));
      await _checkExistingApplication();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_hasApplied && _existingApplication != null) {
      final status = _existingApplication?['status']?.toString() ?? 'pending';
      return Scaffold(
        appBar: AppBar(title: const Text('Transport Application')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.check_circle
                        : status == 'rejected'
                            ? Icons.cancel
                            : Icons.pending,
                    size: 64,
                    color: status == 'approved'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text('Status: $status',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 16),
                  if (status == 'approved' &&
                      _existingApplication?['challanUrl'] != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ChallanViewScreen()));
                      },
                      child: const Text('View Challan'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Apply Transport')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(
              controller: _phoneController,
              decoration: _inputDecoration('Phone Number', Icons.phone),
              enabled: false),
          const SizedBox(height: 12),
          TextField(
              controller: _emailController,
              decoration: _inputDecoration('Email', Icons.email),
              enabled: false),
          const SizedBox(height: 12),
          TextField(
              controller: _regIdController,
              decoration: _inputDecoration(
                  'Registration / University ID', Icons.badge),
              enabled: false),
          const SizedBox(height: 12),
          TextField(
              controller: _departmentController,
              decoration: _inputDecoration('Department', Icons.business),
              enabled: false),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedRoute.isEmpty ? null : _selectedRoute,
            hint: const Text('Select Route'),
            items: _routesList
                .map<DropdownMenuItem<String>>((String route) =>
                    DropdownMenuItem<String>(value: route, child: Text(route)))
                .toList(),
            onChanged: (String? value) {
              if (value != null) setState(() => _selectedRoute = value);
            },
            decoration: _inputDecoration('Route', Icons.route),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: _submitApplication,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('Submit Application')),
        ]),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  }
}