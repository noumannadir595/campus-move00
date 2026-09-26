import 'package:flutter/material.dart';

import '../core/database.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});
  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    final feedbackSnap = await getDatabase().ref('feedbacks').get();
    if (feedbackSnap.exists && mounted) {
      final feedbacks = feedbackSnap.value as Map<dynamic, dynamic>;
      setState(() {
        _feedbacks = feedbacks.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Feedback')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _feedbacks.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      const Icon(Icons.feedback, color: Colors.orange),
                  title: Text(_feedbacks[i]['name']),
                  subtitle: Text(
                      'Email: ${_feedbacks[i]['email']}\nComment: ${_feedbacks[i]['comment']}'),
                  isThreeLine: true,
                ),
              ),
            ),
    );
  }
}