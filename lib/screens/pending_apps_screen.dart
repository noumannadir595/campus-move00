import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../core/notifications.dart';

class PendingAppsScreen extends StatefulWidget {
  const PendingAppsScreen({super.key});
  @override
  State<PendingAppsScreen> createState() => _PendingAppsScreenState();
}

class _PendingAppsScreenState extends State<PendingAppsScreen> {
  List<Map<String, dynamic>> _pendingApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingApps();
  }

  Future<void> _loadPendingApps() async {
    setState(() => _isLoading = true);
    final appsSnap = await getDatabase().ref('applications').get();
    if (appsSnap.exists && mounted) {
      final apps = appsSnap.value as Map<dynamic, dynamic>;
      final allApps = apps.entries
          .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
          .toList();
      setState(() {
        _pendingApps =
            allApps.where((a) => a['status'] == 'pending').toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveApplication(String appKey) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
                content: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Uploading challan...')
            ])));
    try {
      final result =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')));
        return;
      }
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension ?? 'file';
      final fileName =
          'challan_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = FirebaseStorage.instance.ref().child('challans/$fileName');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      await getDatabase().ref('applications/$appKey').update({
        'status': 'approved',
        'challanUrl': downloadUrl,
        'paymentStatus': 'pending',
      });
      showReminder('Application Approved',
          'Your transport application has been approved. Please download challan and upload payment proof.');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Application approved & challan uploaded')));
        _loadPendingApps();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectApplication(String appKey) async {
    await getDatabase()
        .ref('applications/$appKey')
        .update({'status': 'rejected'});
    showReminder('Application Rejected',
        'Your transport application has been rejected.');
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rejected')));
      _loadPendingApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingApps.isEmpty
              ? const Center(child: Text('No pending applications'))
              : ListView.builder(
                  itemCount: _pendingApps.length,
                  itemBuilder: (ctx, i) {
                    final app = _pendingApps[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(app['name']),
                        subtitle: Text(
                            'Route: ${app['route']} | Type: ${app['userType']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📧 Email: ${app['email']}'),
                                Text('📞 Phone: ${app['phone']}'),
                                Text('🏛 Department: ${app['department']}'),
                                Text(
                                    '🆔 ${app['userType'] == 'student' ? 'Registration' : 'University ID'}: ${app['regId']}'),
                                Text(
                                    '📅 Submitted: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(app['submittedAt'] ?? 0))}'),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                        onPressed: () =>
                                            _approveApplication(app['id']),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green)),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                        onPressed: () =>
                                            _rejectApplication(app['id']),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}