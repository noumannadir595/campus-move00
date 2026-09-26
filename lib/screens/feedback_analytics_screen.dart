import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';

class FeedbackAnalyticsScreen extends StatefulWidget {
  const FeedbackAnalyticsScreen({super.key});
  @override
  State<FeedbackAnalyticsScreen> createState() =>
      _FeedbackAnalyticsScreenState();
}

class _FeedbackAnalyticsScreenState
    extends State<FeedbackAnalyticsScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('feedbacks').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _feedbacks =
            data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final positive = _feedbacks
        .where((f) =>
            f['comment'].toString().toLowerCase().contains('good') ||
            f['comment'].toString().toLowerCase().contains('nice'))
        .length;
    final negative = _feedbacks.length - positive;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Feedback Sentiment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
                height: 200,
                child: PieChart(PieChartData(sections: [
                  PieChartSectionData(
                      value: positive.toDouble(),
                      title: 'Positive ($positive)',
                      color: Colors.green,
                      radius: 60),
                  PieChartSectionData(
                      value: negative.toDouble(),
                      title: 'Negative ($negative)',
                      color: Colors.red,
                      radius: 60),
                ]))),
            const SizedBox(height: 20),
            const Text('Recent Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
                child: ListView.builder(
                    itemCount: _feedbacks.length,
                    itemBuilder: (ctx, i) => Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                            title: Text(_feedbacks[i]['name']),
                            subtitle: Text(_feedbacks[i]['comment']))))),
          ],
        ),
      ),
    );
  }
}