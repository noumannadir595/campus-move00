import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import 'admin_card_upload_screen.dart';

class AllAppsScreen extends StatefulWidget {
  const AllAppsScreen({super.key});

  @override
  State<AllAppsScreen> createState() => _AllAppsScreenState();
}

class _AllAppsScreenState extends State<AllAppsScreen> {
  List<Map<String, dynamic>> _apps = [];
  bool _isLoading = true;
  String _filter = 'all';

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
            _apps = all;
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

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _apps;
    return _apps.where((a) => a['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Applications'),
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
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', 'all'),
                  const SizedBox(width: 8),
                  _chip('Processing', 'processing'),
                  const SizedBox(width: 8),
                  _chip('Approved', 'approved'),
                  const SizedBox(width: 8),
                  _chip('Rejected', 'rejected'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No applications',
                        subtitle: 'Nothing to show here',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApps,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.grey[700],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> app) {
    final status = app['status']?.toString() ?? 'processing';
    final color = _statusColor(status);

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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: color,
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

            // Actions
            if (status == 'approved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCardUploadScreen(
                        userId: app['userId'],
                        userName: app['name'] ?? 'User',
                        routeName: app['route'] ?? '',
                        regId: app['regId'] ?? '',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Upload Transport Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
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

  Color _statusColor(String s) {
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

  String _timeAgo(int ts) {
    if (ts == 0) return '';
    final diff = DateTime.now().millisecondsSinceEpoch - ts;
    if (diff < 60000) return '${(diff / 1000).toInt()}s ago';
    if (diff < 3600000) return '${(diff / 60000).toInt()}m ago';
    if (diff < 86400000) return '${(diff / 3600000).toInt()}h ago';
    return DateFormat.yMMMd()
        .format(DateTime.fromMillisecondsSinceEpoch(ts));
  }
}