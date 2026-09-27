import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';
import 'challan_view_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _transportCard;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profilePicUrl;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _guardianNameCtrl = TextEditingController();
  final TextEditingController _guardianPhoneCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _guardianNameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final uid = user.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();

      if (!userSnap.exists) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
        return;
      }

      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      _guardianNameCtrl.text = userData['guardianName']?.toString() ?? '';
      _guardianPhoneCtrl.text = userData['guardianPhone']?.toString() ?? '';

      final appSnap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? appData;
      if (appSnap.exists && appSnap.value != null) {
        final apps = Map<dynamic, dynamic>.from(appSnap.value as Map);
        if (apps.isNotEmpty) {
          appData = Map<String, dynamic>.from(apps.values.first);
        }
      }

      final cardSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? cardData;
      if (cardSnap.exists && cardSnap.value != null) {
        final cards = Map<dynamic, dynamic>.from(cardSnap.value as Map);
        if (cards.isNotEmpty) {
          cardData = Map<String, dynamic>.from(cards.values.first);
        }
      }

      if (!mounted) return;
      setState(() {
        _userData = userData;
        _profilePicUrl = userData['profilePic']?.toString();
        _application = appData;
        _transportCard = cardData;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePic() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
      );

      if (picked == null) return;

      setState(() => _isSaving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child('profilePics/$uid.jpg');

      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await getDatabase().ref('users/$uid').update({'profilePic': url});

      if (!mounted) return;
      setState(() {
        _profilePicUrl = url;
        _isSaving = false;
      });
      CustomSnackbar.success(context, 'Profile picture updated!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  Future<void> _updateGuardian() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      setState(() => _isSaving = true);

      await getDatabase().ref('users/$uid').update({
        'guardianName': _guardianNameCtrl.text.trim(),
        'guardianPhone': _guardianPhoneCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomSnackbar.success(context, 'Guardian info updated!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    if (newPass.isEmpty) {
      CustomSnackbar.warning(context, 'Please enter new password');
      return;
    }

    if (newPass.length < 6) {
      CustomSnackbar.warning(context, 'Password must be at least 6 characters');
      return;
    }

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPass);
      if (!mounted) return;
      CustomSnackbar.success(context, 'Password changed successfully!');
      _newPasswordCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  Future<void> _downloadChallan(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        CustomSnackbar.error(context, 'Cannot open file');
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==================== PROFILE HEADER ====================
          Center(
            child: Stack(
              children: [
                // Gradient border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage(_profilePicUrl!)
                        : null,
                    child: _profilePicUrl == null
                        ? const Icon(Icons.person,
                            size: 54, color: AppColors.primary)
                        : null,
                  ),
                ),
                // Camera button
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _updateProfilePic,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _userData!['name'] ?? 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _userData!['email'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ==================== INFO SECTION ====================
          _buildSection(
            title: 'Account Information',
            icon: Icons.person_rounded,
            children: [
              _buildInfoTile(Icons.phone_rounded, 'Phone',
                  _userData!['phone'] ?? 'N/A'),
              _buildInfoTile(Icons.business_rounded, 'Department',
                  _userData!['department'] ?? 'N/A'),
              _buildInfoTile(
                Icons.badge_rounded,
                _userData!['userType'] == 'student'
                    ? 'Registration Number'
                    : 'University ID',
                _userData!['registrationNumber'] ??
                    _userData!['universityId'] ??
                    'N/A',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==================== GUARDIAN SECTION ====================
          _buildSection(
            title: 'Guardian Information',
            icon: Icons.family_restroom_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _guardianNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Guardian Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _guardianPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Guardian Phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        label: 'Save Guardian Info',
                        isLoading: _isSaving,
                        icon: Icons.save_rounded,
                        onPressed: _updateGuardian,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==================== SECURITY SECTION ====================
          _buildSection(
            title: 'Security',
            icon: Icons.lock_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _newPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.vpn_key_rounded),
                        label: const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==================== APPLICATION STATUS ====================
          _buildSection(
            title: 'Application Status',
            icon: Icons.assignment_rounded,
            children: [
              if (_application != null) ...[
                _buildInfoTile(
                  Icons.route_rounded,
                  'Route',
                  _application!['route'] ?? 'N/A',
                ),
                _buildInfoTile(
                  Icons.info_rounded,
                  'Status',
                  _application!['status'] ?? 'Pending',
                ),
                _buildInfoTile(
                  Icons.payments_rounded,
                  'Payment',
                  _application!['paymentStatus'] ?? 'Pending',
                ),
                if (_application!['status'] == 'approved' &&
                    _application!['challanUrl'] != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadChallan(
                            _application!['challanUrl']),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download Challan'),
                      ),
                    ),
                  ),
                if (_application!['paymentStatus'] == 'pending')
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChallanViewScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('View Challan'),
                      ),
                    ),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No application submitted yet.'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ==================== TRANSPORT CARD ====================
          _buildSection(
            title: 'Transport Card',
            icon: Icons.credit_card_rounded,
            children: [
              if (_transportCard != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.credit_card,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Campus Move',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Card #: ${_transportCard!['cardNumber'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_transportCard!['expiry'] ?? 0))}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Card not generated yet.'),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================== LOGOUT ====================
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}