import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

class TransportFeesScreen extends StatefulWidget {
  const TransportFeesScreen({super.key});

  @override
  State<TransportFeesScreen> createState() => _TransportFeesScreenState();
}

class _TransportFeesScreenState extends State<TransportFeesScreen> {
  List<Map<String, dynamic>> _fees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() => _isLoading = true);
    try {
      final snap = await getDatabase().ref('feeStructure').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final list = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        list.sort((a, b) {
          final aNum = int.tryParse(a['routeNumber']?.toString() ?? '') ?? 999;
          final bNum = int.tryParse(b['routeNumber']?.toString() ?? '') ?? 999;
          return aNum.compareTo(bNum);
        });
        if (mounted) {
          setState(() {
            _fees = list;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Fees'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFees,
          ),
        ],
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 4,
              itemBuilder: (_, __) => const SkeletonCard(),
            )
          : _fees.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Fee Structure',
                  subtitle:
                      'Admin has not published any fee structure yet',
                )
              : RefreshIndicator(
                  onRefresh: _loadFees,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primaryLight.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.primary, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Route-wise fees per semester. Please check your assigned route for details.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Fee list
                      ..._fees.map(_buildFeeCard),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> fee) {
    final amount = fee['amount'] ?? 0;
    final formattedAmount = NumberFormat.decimalPattern().format(amount);
    final routeNumber = fee['routeNumber']?.toString() ?? '?';
    final routeName = fee['routeName']?.toString() ?? 'N/A';
    final semester = fee['semester']?.toString() ?? '';
    final description = fee['description']?.toString() ?? '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Route badge
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.route_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        routeNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Route name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (semester.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    semester,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Amount row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.payments_rounded,
                      color: Colors.green.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Total Fee (per semester)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Text(
                  'Rs. $formattedAmount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}