import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import 'admin_card_upload_screen.dart';

class AdminSearchScreen extends StatefulWidget {
  const AdminSearchScreen({super.key});

  @override
  State<AdminSearchScreen> createState() => _AdminSearchScreenState();
}

class _AdminSearchScreenState extends State<AdminSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;

  // Data caches
  List<Map<String, dynamic>> _allApplications = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allRoutes = [];
  Map<String, Map<String, dynamic>> _cardsByUser = {};

  bool _isLoading = true;
  String _query = '';
  String _activeFilter = 'all'; // all, applications, users, routes

  @override
  void initState() {
    super.initState();
    _loadAllData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final appsSnap = await getDatabase().ref('applications').get();
      final usersSnap = await getDatabase().ref('users').get();
      final routesSnap = await getDatabase().ref('routes').get();
      final cardsSnap = await getDatabase().ref('transportCards').get();

      List<Map<String, dynamic>> apps = [];
      List<Map<String, dynamic>> users = [];
      List<Map<String, dynamic>> routes = [];
      Map<String, Map<String, dynamic>> cards = {};

      if (appsSnap.exists) {
        final data = Map<dynamic, dynamic>.from(appsSnap.value as Map);
        apps = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        apps.sort((a, b) =>
            ((b['submittedAt'] ?? 0) as int)
                .compareTo((a['submittedAt'] ?? 0) as int));
      }

      if (usersSnap.exists) {
        final data = Map<dynamic, dynamic>.from(usersSnap.value as Map);
        users = data.entries
            .map((e) => {'uid': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
      }

      if (routesSnap.exists) {
        final data = Map<dynamic, dynamic>.from(routesSnap.value as Map);
        routes = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
      }

      if (cardsSnap.exists) {
        final data = Map<dynamic, dynamic>.from(cardsSnap.value as Map);
        for (var entry in data.entries) {
          final card = Map<String, dynamic>.from(entry.value);
          final uid = card['userId']?.toString();
          if (uid != null) cards[uid] = card;
        }
      }

      if (!mounted) return;
      setState(() {
        _allApplications = apps;
        _allUsers = users;
        _allRoutes = routes;
        _cardsByUser = cards;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  // ==================== FILTER LOGIC ====================
  List<Map<String, dynamic>> get _matchedApplications {
    if (_query.isEmpty) return [];
    return _allApplications.where((a) {
      return _matchField(a['name'], _query) ||
          _matchField(a['email'], _query) ||
          _matchField(a['regId'], _query) ||
          _matchField(a['route'], _query) ||
          _matchField(a['phone'], _query) ||
          _matchField(a['department'], _query) ||
          _matchField(a['status'], _query) ||
          _matchField(a['userType'], _query);
    }).toList();
  }

  List<Map<String, dynamic>> get _matchedUsers {
    if (_query.isEmpty) return [];
    return _allUsers.where((u) {
      return _matchField(u['name'], _query) ||
          _matchField(u['email'], _query) ||
          _matchField(u['phone'], _query) ||
          _matchField(u['role'], _query) ||
          _matchField(u['userType'], _query) ||
          _matchField(u['registrationNumber'], _query) ||
          _matchField(u['universityId'], _query);
    }).toList();
  }

  List<Map<String, dynamic>> get _matchedRoutes {
    if (_query.isEmpty) return [];
    return _allRoutes.where((r) {
      return _matchField(r['name'], _query) ||
          _matchField(r['routeNumber'], _query) ||
          _matchField(r['stops'], _query);
    }).toList();
  }

  bool _matchField(dynamic field, String query) {
    if (field == null) return false;
    return field.toString().toLowerCase().contains(query);
  }

  int get _totalResults =>
      _matchedApplications.length + _matchedUsers.length + _matchedRoutes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search name, email, reg ID, route...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
              ? _buildEmptyQuery()
              : _totalResults == 0
                  ? _buildNoResults()
                  : _buildResults(),
    );
  }

  // ==================== EMPTY QUERY STATE ====================
  Widget _buildEmptyQuery() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 72, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search Admin Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Search by name, email, registration ID,\nroute, phone, or status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            // Quick search chips
            const Text(
              'Quick searches:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _quickChip('pending'),
                _quickChip('processing'),
                _quickChip('approved'),
                _quickChip('rejected'),
                _quickChip('driver'),
                _quickChip('student'),
                _quickChip('faculty'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _searchCtrl.text = text;
        setState(() => _query = text.toLowerCase());
      },
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  // ==================== NO RESULTS ====================
  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'No results found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RESULTS ====================
  Widget _buildResults() {
    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all', _totalResults),
                const SizedBox(width: 8),
                _filterChip(
                    'Applications', 'applications', _matchedApplications.length),
                const SizedBox(width: 8),
                _filterChip('Users', 'users', _matchedUsers.length),
                const SizedBox(width: 8),
                _filterChip('Routes', 'routes', _matchedRoutes.length),
              ],
            ),
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Applications
              if ((_activeFilter == 'all' ||
                      _activeFilter == 'applications') &&
                  _matchedApplications.isNotEmpty) ...[
                _sectionHeader(
                    'Applications', _matchedApplications.length, Icons.assignment),
                ..._matchedApplications
                    .map((a) => _buildApplicationCard(a))
                    ,
                const SizedBox(height: 16),
              ],

              // Users
              if ((_activeFilter == 'all' || _activeFilter == 'users') &&
                  _matchedUsers.isNotEmpty) ...[
                _sectionHeader('Users', _matchedUsers.length, Icons.people),
                ..._matchedUsers.map((u) => _buildUserCard(u)),
                const SizedBox(height: 16),
              ],

              // Routes
              if ((_activeFilter == 'all' || _activeFilter == 'routes') &&
                  _matchedRoutes.isNotEmpty) ...[
                _sectionHeader('Routes', _matchedRoutes.length, Icons.route),
                ..._matchedRoutes.map((r) => _buildRouteCard(r)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final selected = _activeFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _activeFilter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : Colors.grey[700],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _sectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==================== APPLICATION CARD ====================
  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = app['status']?.toString() ?? 'processing';
    final statusColor = _statusColor(status);
    final card = _cardsByUser[app['userId']];
    final hasCard = card != null &&
        card['cardImageBase64'] != null &&
        card['cardImageBase64'].toString().isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (hasCard)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CARD ✓',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              app['name'] ?? 'N/A',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _infoLine(Icons.badge_outlined, app['regId'] ?? 'N/A'),
            _infoLine(Icons.email_outlined, app['email'] ?? 'N/A'),
            _infoLine(Icons.route_outlined, app['route'] ?? 'N/A'),

            // Actions
            if (status == 'processing') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectApplication(app['id']),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveApplication(app['id']),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'approved') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCardUpload(app),
                  icon: Icon(
                      hasCard ? Icons.edit_rounded : Icons.upload_rounded,
                      size: 16),
                  label: Text(hasCard ? 'Update Card' : 'Upload Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasCard
                        ? AppColors.primary
                        : Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== USER CARD ====================
  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? 'user';
    final color = role == 'admin'
        ? Colors.purple
        : (role == 'driver' ? Colors.teal : Colors.blue);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role == 'admin'
                    ? Icons.admin_panel_settings
                    : (role == 'driver'
                        ? Icons.drive_eta
                        : Icons.person),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user['email'] ?? 'N/A',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ROUTE CARD ====================
  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${route['routeNumber']}: ${route['name']}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    route['stops']?.toString() ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
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

  // ==================== ACTIONS ====================
  Future<void> _approveApplication(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Application?'),
        content:
            const Text('This will grant transport access to the user.'),
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
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Failed: $e');
    }
  }

  Future<void> _rejectApplication(String appId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Application?'),
        content: const Text('Are you sure?'),
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
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Failed: $e');
    }
  }

  void _openCardUpload(Map<String, dynamic> app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCardUploadScreen(
          userId: app['userId'],
          userName: app['name'] ?? 'User',
          routeName: app['route'] ?? '',
          regId: app['regId'] ?? '',
        ),
      ),
    ).then((_) => _loadAllData());
  }
}