import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendFeedback() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    setState(() => _isSending = true);
    await getDatabase().ref('feedbacks').push().set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'comment': _commentController.text.trim(),
      'timestamp': ServerValue.timestamp,
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Thank you!')));
      Navigator.pop(context);
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Send Feedback')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Your Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Your Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Comment', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: _isSending ? null : _sendFeedback,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50)),
                child: _isSending
                    ? const CircularProgressIndicator()
                    : const Text('Send Feedback'))
          ]),
        ),
      );
}