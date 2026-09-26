import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/database.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<Map<String, dynamic>> _attendance = [];
  bool _loading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('attendance').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _attendance =
            data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final filtered = _attendance
        .where((a) =>
            DateFormat('yyyy-MM').format(
                DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) ==
            _selectedMonth)
        .toList();
    pdf.addPage(pw.MultiPage(build: (context) => [
          pw.Header(
              level: 0,
              child:
                  pw.Text('Monthly Attendance Report - $_selectedMonth')),
          pw.Table(border: pw.TableBorder.all(), children: [
            pw.TableRow(children: [
              pw.Text('Student Name'),
              pw.Text('Route'),
              pw.Text('Date')
            ]),
            ...filtered.map((a) => pw.TableRow(children: [
                  pw.Text(a['studentName']),
                  pw.Text(a['route']),
                  pw.Text(DateFormat.yMMMd().format(
                      DateTime.fromMillisecondsSinceEpoch(a['timestamp'])))
                ]))
          ])
        ]));
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'attendance_$_selectedMonth.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report'), actions: [
        IconButton(
            icon: const Icon(Icons.picture_as_pdf), onPressed: _generatePDF)
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Text('Select Month: '),
              Expanded(
                  child: TextFormField(
                      initialValue: _selectedMonth,
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (date != null) {
                          setState(() {
                            _selectedMonth =
                                DateFormat('yyyy-MM').format(date);
                            _loadAttendance();
                          });
                        }
                      },
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()))),
            ])),
        Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _attendance
                        .where((a) =>
                            DateFormat('yyyy-MM').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    a['timestamp'])) ==
                            _selectedMonth)
                        .length,
                    itemBuilder: (ctx, i) {
                      final filtered = _attendance
                          .where((a) =>
                              DateFormat('yyyy-MM').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      a['timestamp'])) ==
                              _selectedMonth)
                          .toList();
                      final a = filtered[i];
                      return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                              title: Text(a['studentName']),
                              subtitle: Text(
                                  'Route: ${a['route']} | ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(a['timestamp']))}')));
                    },
                  )),
      ]),
    );
  }
}