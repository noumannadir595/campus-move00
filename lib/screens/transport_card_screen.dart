import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';

class TransportCardScreen extends StatefulWidget {
  const TransportCardScreen({super.key});

  @override
  State<TransportCardScreen> createState() => _TransportCardScreenState();
}

class _TransportCardScreenState extends State<TransportCardScreen> {
  Map<String, dynamic>? _cardData;
  Map<String, dynamic>? _application;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Application status check
      final appSnap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? app;
      if (appSnap.exists) {
        final data = Map<dynamic, dynamic>.from(appSnap.value as Map);
        if (data.isNotEmpty) {
          app = Map<String, dynamic>.from(data.values.first);
        }
      }

      // Card check
      final cardSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? card;
      if (cardSnap.exists) {
        final data = Map<dynamic, dynamic>.from(cardSnap.value as Map);
        if (data.isNotEmpty) {
          card = Map<String, dynamic>.from(data.values.first);
        }
      }

      if (!mounted) return;
      setState(() {
        _application = app;
        _cardData = card;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transport Card'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
    );
  }

  Widget _buildContent() {
    // No application
    if (_application == null) {
      return const EmptyState(
        icon: Icons.credit_card_outlined,
        title: 'No Application',
        subtitle: 'Please apply for transport first',
      );
    }

    final status = _application!['status']?.toString() ?? 'processing';

    // Rejected
    if (status == 'rejected') {
      return _statusCard(
        icon: Icons.cancel_rounded,
        color: Colors.red,
        title: 'Application Rejected',
        subtitle: 'Your transport application was rejected',
      );
    }

    // Processing
    if (status == 'processing') {
      return _statusCard(
        icon: Icons.hourglass_top_rounded,
        color: Colors.orange,
        title: 'Processing',
        subtitle:
            'Your application is being processed.\nCollect voucher from Admission Office and submit fees.',
      );
    }

    // Approved but no card yet
    if (status == 'approved' && _cardData == null) {
      return _statusCard(
        icon: Icons.pending_actions_rounded,
        color: Colors.blue,
        title: 'Card Being Generated',
        subtitle:
            'Your transport access is approved.\nCard will be available soon.',
      );
    }

    // Approved + Card available
    if (status == 'approved' && _cardData != null) {
      return _buildCardView();
    }

    return const EmptyState(
      icon: Icons.info_outline_rounded,
      title: 'No data',
      subtitle: 'Please check back later',
    );
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 72, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardView() {
    final card = _cardData!;
    final hasImage = card['cardImageBase64'] != null &&
        card['cardImageBase64'].toString().isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 10),
        // Card design
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E40AF),
                Color(0xFF7C3AED),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Move',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Transport Card',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Card image (if uploaded by admin)
                    if (hasImage)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(card['cardImageBase64']),
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.white70, size: 40),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_empty,
                                    color: Colors.white70, size: 32),
                                SizedBox(height: 8),
                                Text(
                                  'Card image not uploaded yet',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Card details
                    _cardInfo(
                        'Name', card['userName']?.toString() ?? 'N/A'),
                    const SizedBox(height: 6),
                    _cardInfo(
                        'Reg ID', card['regId']?.toString() ?? 'N/A'),
                    const SizedBox(height: 6),
                    _cardInfo('Route',
                        card['route']?.toString() ?? 'N/A'),

                    const SizedBox(height: 16),

                    // Footer
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CARD NUMBER',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                card['cardNumber']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'VALID TILL',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _formatExpiry(card['expiry']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Info box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 26),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have full transport access. Show this card when boarding.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatExpiry(dynamic expiry) {
    try {
      final ts = (expiry ?? 0) as int;
      if (ts == 0) return 'N/A';
      return DateFormat('MMM yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(ts));
    } catch (_) {
      return 'N/A';
    }
  }
}