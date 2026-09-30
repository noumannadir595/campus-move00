import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/empty_state.dart';

class ChallanViewScreen extends StatefulWidget {
  const ChallanViewScreen({super.key});

  @override
  State<ChallanViewScreen> createState() => _ChallanViewScreenState();
}

class _ChallanViewScreenState extends State<ChallanViewScreen> {
  Map<String, dynamic>? _challanData;
  bool _isLoading = true;
  bool _isDownloading = false;

  static const int defaultFee = 35000;

  @override
  void initState() {
    super.initState();
    _fetchChallan();
  }

  Future<void> _fetchChallan() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (snap.exists) {
        final data = snap.value as Map<dynamic, dynamic>;
        if (data.isNotEmpty) {
          final app = Map<String, dynamic>.from(data.values.first);

          final userSnap = await getDatabase().ref('users/$uid').get();
          final userData = userSnap.exists
              ? Map<String, dynamic>.from(userSnap.value as Map)
              : <String, dynamic>{};

          int feeAmount = defaultFee;
          final routeName = app['route']?.toString() ?? '';
          try {
            final feeSnap = await getDatabase().ref('feeStructure').get();
            if (feeSnap.exists) {
              final feeData = Map<dynamic, dynamic>.from(feeSnap.value as Map);
              for (var entry in feeData.entries) {
                final f = Map<dynamic, dynamic>.from(entry.value);
                final fullName =
                    'Route ${f['routeNumber'] ?? ''}: ${f['routeName'] ?? ''}';
                if (fullName == routeName) {
                  feeAmount = int.tryParse(
                          f['amount']?.toString() ?? '$defaultFee') ??
                      defaultFee;
                  break;
                }
              }
            }
          } catch (_) {}

          if (!mounted) return;
          setState(() {
            _challanData = {
              'name': app['name'] ?? userData['name'] ?? 'N/A',
              'email': app['email'] ?? userData['email'] ?? 'N/A',
              'regId': app['regId'] ?? 'N/A',
              'department':
                  app['department'] ?? userData['department'] ?? 'N/A',
              'route': routeName,
              'semester': _getCurrentSemester(),
              'amount': feeAmount,
              'status': app['status'] ?? 'processing',
              'voucherStatus': app['voucherStatus'] ?? 'not_collected',
            };
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _getCurrentSemester() {
    final month = DateTime.now().month;
    final year = DateTime.now().year;
    if (month >= 1 && month <= 6) {
      return 'Spring $year';
    } else {
      return 'Fall $year';
    }
  }

  Future<void> _downloadPdf() async {
    if (_challanData == null) return;
    setState(() => _isDownloading = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CAMPUS MOVE',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'COMSATS University Islamabad',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Transport Fee Challan',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),

                pw.Text(
                  'STUDENT DETAILS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _pdfRow('Name', _challanData!['name']),
                _pdfRow('Email', _challanData!['email']),
                _pdfRow('Registration ID', _challanData!['regId']),
                _pdfRow('Department', _challanData!['department']),
                pw.SizedBox(height: 24),

                pw.Text(
                  'CHALLAN DETAILS',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _pdfRow('Route', _challanData!['route']),
                _pdfRow('Semester', _challanData!['semester']),
                _pdfRow('Status',
                    _challanData!['status'].toString().toUpperCase()),
                pw.SizedBox(height: 32),

                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL AMOUNT',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Rs. ${_challanData!['amount']}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INSTRUCTIONS',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('1. Submit fees at any bank.',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('2. Show this challan to Transport Desk.',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('3. Wait for admin verification.',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('4. Collect your transport card after approval.',
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Generated on ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'CampusMove_Challan_${_challanData!['regId']}_${_challanData!['semester']}.pdf',
      );

      if (!mounted) return;
      setState(() => _isDownloading = false);
      CustomSnackbar.success(context, 'PDF downloaded!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloading = false);
      CustomSnackbar.error(context, 'Error: $e');
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Challan'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _challanData == null
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Challan Available',
                  subtitle: 'Please apply for transport first',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusBanner(),
                      const SizedBox(height: 16),

                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.05),
                                AppColors.primaryLight
                                    .withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fee Challan',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'COMSATS University Islamabad',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 12),

                                _buildInfoRow(
                                    'Name', _challanData!['name']),
                                _buildInfoRow(
                                    'Email', _challanData!['email']),
                                _buildInfoRow('Registration ID',
                                    _challanData!['regId']),
                                _buildInfoRow('Department',
                                    _challanData!['department']),
                                _buildInfoRow(
                                    'Route', _challanData!['route']),
                                _buildInfoRow(
                                    'Semester', _challanData!['semester']),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TOTAL AMOUNT',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Per Semester',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Rs. ${_challanData!['amount']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadPdf,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          _isDownloading ? 'Downloading...' : 'DOWNLOAD PDF',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Instructions',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _instructionStep('1',
                                'Collect your challan from Admission Office (Transport Desk).'),
                            _instructionStep(
                                '2', 'Submit fees at any bank branch.'),
                            _instructionStep('3',
                                'Show the paid challan to Transport Desk.'),
                            _instructionStep('4',
                                'Wait for admin to verify your payment.'),
                            _instructionStep('5',
                                'Your transport card will be uploaded by admin.'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _challanData!['status'];
    final voucher = _challanData!['voucherStatus'];

    Color color;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        title = 'Approved';
        subtitle = 'Payment verified. Card will be uploaded shortly.';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_rounded;
        title = 'Rejected';
        subtitle = 'Your application was rejected.';
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top_rounded;
        title = 'Processing';
        subtitle = voucher == 'verified'
            ? 'Voucher verified. Waiting for admin approval.'
            : 'Collect voucher and submit fees.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12, color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}