import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  final String feature;
  const ComingSoonScreen({super.key, required this.feature});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(feature)),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('🚧 Coming Soon 🚧',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('This feature will be available in the next update.'),
          ],
        ),
      ),
    );
  }
}