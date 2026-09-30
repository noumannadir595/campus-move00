import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import 'admin_card_upload_screen.dart';

class AdminTransportCardsScreen extends StatefulWidget {
  const AdminTransportCardsScreen({super.key});

  @override
  State<AdminTransportCardsScreen> createState() =>
      _AdminTransportCardsScreenState();
}

class _AdminTransportCardsScreenState
    extends State<AdminTransportCardsScreen> {
  List<Map<String, dynamic>> _applications = [];
  Map<String, Map<String, dynamic>> _cardsByUser = {};
  bool _isLoading = true;
  String _filter = 'all'; // all, with_card, without_card

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load approved applications
      final appsSnap = await getDatabase().ref('applications').get();

      // Load all transport cards
      final cardsSnap = await getDatabase().ref('transportCards').get();

      Map<String, Map<String, dynamic>> cardsByUser = {};
      if (cardsSnap.exists) {
        final cardData = Map<dynamic, dynamic>.from(cardsSnap.value as Map);
        for (var entry in cardData.entries) {
          final card = Map<String, dynamic>.from(entry.value);
          final userId = card['userId']?.toString();
          if (userId != null) {
            cardsByUser[userId] = card;
          }
        }
      }

      List<Map<String, dynamic>> apps = [];
      if (appsSnap.exists) {
        final data = Map<dynamic, dynamic>.from(appsSnap.value as Map);
        apps = data.entries
            .map((e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value),
                })
            .where((a) => a['status'] == 'approved')
            .toList();
        apps.sort((a, b) =>
            ((b['submittedAt'] ?? 0) as int)
                .compareTo((a['submittedAt'] ?? 0) as int));
      }

      if (!mounted) return;
      setState(() {
        _applications = apps;
        _cardsByUser = cardsByUser;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case 'with_card':
        return _applications
            .where((a) =>
                _cardsByUser[a['userId']] != null &&
                _cardsByUser[a['userId']]!['cardImageBase64'] != null &&
                _cardsByUser[a['userId']]!['cardImageBase64'].toString().isNotEmpty)
            .toList();
      case 'without_card':
        return _applications
            .where((a) =>
                _cardsByUser[a['userId']] == null ||
                _cardsByUser[a['userId']]!['cardImageBase64'] == null ||
                _cardsByUser[a['userId']]!['cardImageBase64'].toString().isEmpty)
            .toList();
      default:
        return _applications;
    }
  }

  void _openUpload(Map<String, dynamic> app) {
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
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Cards'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
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
                  _chip('With Card', 'with_card'),
                  const SizedBox(width: 8),
                  _chip('Without Card', 'without_card'),
                ],
              ),
            ),
          ),

          // Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statTile(
                      'Total Approved', _applications.length, Colors.blue),
                ),
                Expanded(
                  child: _statTile('With Card', _cardsByUser.length,
                      Colors.green),
                ),
                Expanded(
                  child: _statTile(
                    'Pending Cards',
                    _applications.length - _cardsByUser.length,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.credit_card_outlined,
                        title: 'No approved applications',
                        subtitle: 'Approve applications first',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildUserCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
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

  Widget _buildUserCard(Map<String, dynamic> app) {
    final userId = app['userId'];
    final card = _cardsByUser[userId];
    final hasImage = card != null &&
        card['cardImageBase64'] != null &&
        card['cardImageBase64'].toString().isNotEmpty;

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
                // Icon with status
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: hasImage
                        ? LinearGradient(colors: [
                            Colors.green.shade400,
                            Colors.green.shade700,
                          ])
                        : LinearGradient(colors: [
                            Colors.orange.shade400,
                            Colors.orange.shade700,
                          ]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasImage
                        ? Icons.credit_card_rounded
                        : Icons.hourglass_empty_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['name'] ?? 'N/A',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        app['regId'] ?? 'N/A',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasImage ? 'CARD READY' : 'PENDING',
                    style: TextStyle(
                      color: hasImage ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card preview thumbnail
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(card['cardImageBase64']),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: Colors.grey.shade200,
                    child:
                        const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Info
            _infoRow(Icons.route_outlined, app['route'] ?? 'N/A'),
            _infoRow(Icons.email_outlined, app['email'] ?? 'N/A'),
            if (card != null)
              _infoRow(
                Icons.confirmation_number_outlined,
                card['cardNumber']?.toString() ?? 'N/A',
              ),

            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openUpload(app),
                icon: Icon(hasImage
                    ? Icons.edit_rounded
                    : Icons.upload_rounded),
                label: Text(
                  hasImage ? 'Update Card' : 'Upload Card',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasImage
                      ? AppColors.primary
                      : Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}