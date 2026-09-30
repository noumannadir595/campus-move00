import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';

class ApplyTransportScreen extends StatefulWidget {
  const ApplyTransportScreen({super.key});

  @override
  State<ApplyTransportScreen> createState() => _ApplyTransportScreenState();
}

class _ApplyTransportScreenState extends State<ApplyTransportScreen> {
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _regIdCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();

  String _selectedRoute = '';
  List<String> _routesList = [];
  bool _hasApplied = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingApplication;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _regIdCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
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

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await getDatabase().ref('users/$uid').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        _nameCtrl.text = data['name']?.toString() ?? '';
        _phoneCtrl.text = data['phone']?.toString() ?? '';
        _emailCtrl.text = data['email']?.toString() ?? '';
        _departmentCtrl.text = data['department']?.toString() ?? '';
        if (data['userType'] == 'student') {
          _regIdCtrl.text = data['registrationNumber']?.toString() ?? '';
        } else {
          _regIdCtrl.text = data['universityId']?.toString() ?? '';
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _loadRoutes() async {
    try {
      final snap = await getDatabase().ref('routes').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final routes = data.entries.map((e) {
          final r = Map<dynamic, dynamic>.from(e.value);
          return 'Route ${r['routeNumber'] ?? ''}: ${r['name'] ?? ''}';
        }).toList();
        if (mounted) setState(() => _routesList = routes);
      }
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> _submitApplication() async {
    if (_selectedRoute.isEmpty) {
      CustomSnackbar.warning(context, 'Please select a route');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (!userSnap.exists) {
        CustomSnackbar.error(context, 'User not found');
        setState(() => _isSubmitting = false);
        return;
      }

      final userData = Map<String, dynamic>.from(userSnap.value as Map);

      await getDatabase().ref('applications').push().set({
        'userId': uid,
        'name': _nameCtrl.text.trim(),
        'userType': userData['userType'],
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'regId': _regIdCtrl.text.trim(),
        'route': _selectedRoute,
        'status': 'processing',
        'voucherStatus': 'not_collected',
        'submittedAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      CustomSnackbar.success(context, 'Application submitted!');
      await _checkExistingApplication();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply Transport'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasApplied && _existingApplication != null
              ? _buildStatusView()
              : _buildFormView(),
    );
  }

  // ==================== FORM VIEW ====================
  Widget _buildFormView() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primaryLight.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fill the form and submit. Admin will process your application.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildField(_nameCtrl, 'Full Name', Icons.person_outline,
                enabled: false),
            const SizedBox(height: 12),
            _buildField(_emailCtrl, 'Email', Icons.email_outlined,
                enabled: false),
            const SizedBox(height: 12),
            _buildField(_phoneCtrl, 'Phone', Icons.phone_outlined,
                enabled: false),
            const SizedBox(height: 12),
            _buildField(_regIdCtrl, 'Registration / University ID',
                Icons.badge_outlined,
                enabled: false),
            const SizedBox(height: 12),
            _buildField(_departmentCtrl, 'Department', Icons.business_outlined,
                enabled: false),
            const SizedBox(height: 12),

            // Route dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedRoute.isEmpty ? null : _selectedRoute,
              hint: const Text('Select Route'),
              isExpanded: true,
              items: _routesList.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v!),
              decoration: const InputDecoration(
                labelText: 'Route',
                prefixIcon: Icon(Icons.route_outlined),
              ),
            ),
            const SizedBox(height: 24),

            LoadingButton(
              label: 'Submit Application',
              isLoading: _isSubmitting,
              icon: Icons.send_rounded,
              onPressed: _submitApplication,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String label, IconData icon,
      {bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ==================== STATUS VIEW ====================
  Widget _buildStatusView() {
    final app = _existingApplication!;
    final status = app['status']?.toString() ?? 'processing';
    final voucherStatus =
        app['voucherStatus']?.toString() ?? 'not_collected';

    return RefreshIndicator(
      onRefresh: _checkExistingApplication,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          // Status icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                size: 72,
                color: _getStatusColor(status),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              _getStatusTitle(status),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _getStatusSubtitle(status),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),

          // Route info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.route, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Application Details',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  _statusRow('Route', app['route'] ?? 'N/A'),
                  _statusRow('Status', status.toUpperCase()),
                  _statusRow('Voucher', _voucherText(voucherStatus)),
                  _statusRow('Name', app['name'] ?? 'N/A'),
                  _statusRow('Reg ID', app['regId'] ?? 'N/A'),
                ],
              ),
            ),
          ),

          // Voucher instruction (only if processing + not collected)
          if (status == 'processing' && voucherStatus == 'not_collected') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.15),
                    Colors.orange.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade800, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Next Steps',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _instructionStep('1',
                      'Visit Admission Office (Transport Desk)'),
                  _instructionStep('2', 'Collect your Challan Voucher'),
                  _instructionStep('3', 'Submit fees at any bank'),
                  _instructionStep('4',
                      'Show Challan to Transport Desk for verification'),
                  _instructionStep(
                      '5', 'Wait for admin approval + card generation'),
                ],
              ),
            ),
          ],

          if (status == 'approved') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.15),
                    Colors.teal.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Transport access granted! Check My Card module.',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (status == 'rejected') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your application was rejected. Contact admin for details.',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _voucherText(String s) {
    switch (s) {
      case 'not_collected':
        return 'Not Collected';
      case 'collected':
        return 'Collected';
      case 'verified':
        return 'Verified';
      default:
        return s;
    }
  }

  Color _getStatusColor(String s) {
    switch (s) {
      case 'processing':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String s) {
    switch (s) {
      case 'processing':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _getStatusTitle(String s) {
    switch (s) {
      case 'processing':
        return 'Processing';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Processing';
    }
  }

  String _getStatusSubtitle(String s) {
    switch (s) {
      case 'processing':
        return 'Your application is being processed';
      case 'approved':
        return 'You have transport access';
      case 'rejected':
        return 'Application was rejected';
      default:
        return '';
    }
  }
}