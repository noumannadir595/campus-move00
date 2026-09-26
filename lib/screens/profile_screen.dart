import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/database.dart';
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
      final picked =
          await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final ref =
            FirebaseStorage.instance.ref().child('profilePics/$uid.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        await getDatabase().ref('users/$uid').update({'profilePic': url});
        if (!mounted) return;
        setState(() => _profilePicUrl = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateGuardian() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await getDatabase().ref('users/$uid').update({
        'guardianName': _guardianNameCtrl.text.trim(),
        'guardianPhone': _guardianPhoneCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian info updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    if (newPass.isEmpty) return;
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPass);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')));
      _newPasswordCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _downloadChallan(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open file')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _refreshData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePicUrl != null
                      ? NetworkImage(_profilePicUrl!)
                      : null,
                  child: _profilePicUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                      onPressed: _updateProfilePic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Name'),
              subtitle: Text(_userData?['name']?.toString() ?? '')),
          ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(_userData?['email']?.toString() ?? '')),
          ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(_userData?['phone']?.toString() ?? '')),
          ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Department'),
              subtitle: Text(_userData?['department']?.toString() ?? '')),
          const Divider(),
          const Text('Guardian Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
              controller: _guardianNameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Guardian Name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(
              controller: _guardianPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Guardian Phone', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _updateGuardian,
              child: const Text('Save Guardian Info')),
          const Divider(),
          const Text('Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'New Password', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change Password')),
          const Divider(),
          const Text('Application Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_application != null) ...[
            ListTile(
              title: Text('Route: ${_application?['route'] ?? ''}'),
              subtitle: Text(
                  'Status: ${_application?['status'] ?? ''} | Payment: ${_application?['paymentStatus'] ?? 'Pending'}'),
            ),
            if (_application?['status'] == 'approved' &&
                _application?['challanUrl'] != null)
              ElevatedButton.icon(
                onPressed: () {
                  _downloadChallan(_application!['challanUrl']);
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Challan'),
              ),
            if (_application?['paymentStatus'] == 'pending')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChallanViewScreen()));
                },
                child: const Text('Upload Payment Proof'),
              ),
          ] else
            const Text('No application submitted yet.'),
          const Divider(),
          const Text('Transport Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_transportCard != null)
            Card(
              color: Colors.blue.shade100,
              child: ListTile(
                title: Text(
                    'Card #: ${_transportCard?['cardNumber'] ?? ''}'),
                subtitle: Text(
                    'Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_transportCard?['expiry'] ?? 0))}'),
              ),
            )
          else
            const Text('Card not generated yet.'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}