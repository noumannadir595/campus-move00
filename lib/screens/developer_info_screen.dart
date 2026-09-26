import 'package:flutter/material.dart';

class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final developers = [
      {
        'name': 'Hafsa Saleem',
        'role': 'Lecturer at CUI',
        'image': 'assets/dev1.png',
        'email': 'hafsasaleem@gmail.com',
        'phone': 'Nil'
      },
      {
        'name': 'Nouman Nadir',
        'role': ' Developer',
        'image': 'assets/dev2.jpeg',
        'email': 'noumannadir595@gmail.com',
        'phone': '+92 325 9869056'
      },
      {
        'name': 'Aqsa',
        'role': ' Developer',
        'image': 'assets/dev3.jpeg',
        'email': 'aqsaqamar0499@gmail.com',
        'phone': 'Nil'
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Info')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: developers.length,
        itemBuilder: (ctx, i) {
          final dev = developers[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(dev['image']!),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 40)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(dev['name']!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(dev['role']!,
                          style: const TextStyle(color: Colors.blue)),
                      const SizedBox(height: 4),
                      Text('Email: ${dev['email']}',
                          style: const TextStyle(fontSize: 12)),
                      Text('Phone: ${dev['phone']}',
                          style: const TextStyle(fontSize: 12))
                    ])),
              ]),
            ),
          );
        },
      ),
    );
  }
}