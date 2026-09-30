import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/empty_state.dart';

class AdminFeeStructureScreen extends StatefulWidget {
  const AdminFeeStructureScreen({super.key});

  @override
  State<AdminFeeStructureScreen> createState() =>
      _AdminFeeStructureScreenState();
}

class _AdminFeeStructureScreenState extends State<AdminFeeStructureScreen> {
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

  // ==================== ADD / EDIT ====================
  Future<void> _addEdit({Map<String, dynamic>? existing}) async {
    final routeNumberCtrl =
        TextEditingController(text: existing?['routeNumber']?.toString() ?? '');
    final routeNameCtrl =
        TextEditingController(text: existing?['routeName']?.toString() ?? '');
    final amountCtrl =
        TextEditingController(text: existing?['amount']?.toString() ?? '');
    final semesterCtrl =
        TextEditingController(text: existing?['semester']?.toString() ?? '');
    final descriptionCtrl = TextEditingController(
        text: existing?['description']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              existing == null ? Icons.add_circle : Icons.edit,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(existing == null ? 'Add Route Fee' : 'Edit Route Fee'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: routeNumberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Route Number',
                  hintText: 'e.g., 1',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: routeNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  hintText: 'e.g., CUI - Sahiwal City',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fee Amount (Rs.)',
                  hintText: 'e.g., 35000',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: semesterCtrl,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  hintText: 'e.g., Spring 2026',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Validation
    if (routeNumberCtrl.text.isEmpty ||
        routeNameCtrl.text.isEmpty ||
        amountCtrl.text.isEmpty) {
      if (!mounted) return;
      CustomSnackbar.warning(context, 'Fill route number, name, and amount');
      return;
    }

    final amount = int.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      CustomSnackbar.warning(context, 'Enter a valid amount');
      return;
    }

    try {
      final data = {
        'routeNumber': routeNumberCtrl.text.trim(),
        'routeName': routeNameCtrl.text.trim(),
        'amount': amount,
        'semester': semesterCtrl.text.trim().isEmpty
            ? _currentSemester()
            : semesterCtrl.text.trim(),
        'description': descriptionCtrl.text.trim(),
        'updatedAt': ServerValue.timestamp,
      };

      if (existing != null) {
        await getDatabase()
            .ref('feeStructure/${existing['id']}')
            .update(data);
        if (!mounted) return;
        CustomSnackbar.success(context, 'Fee updated!');
      } else {
        await getDatabase().ref('feeStructure').push().set({
          ...data,
          'createdAt': ServerValue.timestamp,
        });
        if (!mounted) return;
        CustomSnackbar.success(context, 'Fee added!');
      }
      _loadFees();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  // ==================== DELETE ====================
  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Fee?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await getDatabase().ref('feeStructure/$id').remove();
      if (!mounted) return;
      CustomSnackbar.success(context, 'Fee deleted');
      _loadFees();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  String _currentSemester() {
    final month = DateTime.now().month;
    final year = DateTime.now().year;
    return month >= 1 && month <= 6 ? 'Spring $year' : 'Fall $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Structure'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEdit(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Fee'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fees.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No fee structure yet',
                  subtitle: 'Tap "Add Fee" to create one',
                )
              : RefreshIndicator(
                  onRefresh: _loadFees,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _fees.length,
                    itemBuilder: (ctx, i) => _buildFeeCard(_fees[i]),
                  ),
                ),
    );
  }

  Widget _buildFeeCard(Map<String, dynamic> fee) {
    final amount = fee['amount'] ?? 0;
    final formattedAmount =
        NumberFormat.decimalPattern().format(amount);

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
                // Route number badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.route,
                          color: Colors.white, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        fee['routeNumber']?.toString() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fee['routeName']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fee['semester']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Rs. $formattedAmount',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            if (fee['description'] != null &&
                fee['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fee['description'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _delete(fee['id']),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addEdit(existing: fee),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
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