import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/empty_state.dart';

class PendingAppsScreen extends StatefulWidget {
  const PendingAppsScreen({super.key});

  @override
  State<PendingAppsScreen> createState() => _PendingAppsScreenState();
}

class _PendingAppsScreenState extends State<PendingAppsScreen> {
  List<Map<String, dynamic>> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    try {
      final snap = await getDatabase().ref('applications').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final all = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        all.sort((a, b) =>
            ((b['submittedAt'] ?? 0) as int)
                .compareTo((a['submittedAt'] ?? 0) as int));
        if (mounted) {
          setState(() {
            _apps = all.where((a) => a['status'] == 'processing').toList();
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

  // ==================== APPROVE ====================
  Future<void> _approve(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Application?'),
        content: const Text(
            'This will grant transport access to the user. Confirm after voucher verification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await getDatabase().ref('applications/$appId').update({
        'status': 'approved',
        'voucherStatus': 'verified',
        'approvedAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      CustomSnackbar.success(context, 'Application approved!');
      _loadApps();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Failed: $e');
    }
  }

  // ==================== REJECT ====================
  Future<void> _reject(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application?'),
        content: const Text('Are you sure you want to reject this application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await getDatabase().ref('applications/$appId').update({
        'status': 'rejected',
        'rejectedAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      CustomSnackbar.success(context, 'Application rejected');
      _loadApps();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Applications'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadApps,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'No pending applications',
                  subtitle: 'All caught up!',
                )
              : RefreshIndicator(
                  onRefresh: _loadApps,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _apps.length,
                    itemBuilder: (ctx, i) => _buildCard(_apps[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> app) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PROCESSING',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(app['submittedAt'] ?? 0),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              app['name'] ?? 'N/A',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _infoRow(Icons.email_outlined, app['email'] ?? 'N/A'),
            _infoRow(Icons.phone_outlined, app['phone'] ?? 'N/A'),
            _infoRow(Icons.badge_outlined, app['regId'] ?? 'N/A'),
            _infoRow(Icons.route_outlined, app['route'] ?? 'N/A'),
            _infoRow(Icons.business_outlined, app['department'] ?? 'N/A'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(app['id']),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(app['id']),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _timeAgo(int ts) {
    if (ts == 0) return '';
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    if (diff < 60000) return '${(diff / 1000).toInt()}s ago';
    if (diff < 3600000) return '${(diff / 60000).toInt()}m ago';
    if (diff < 86400000) return '${(diff / 3600000).toInt()}h ago';
    return DateFormat.yMMMd().format(
        DateTime.fromMillisecondsSinceEpoch(ts));
  }
}