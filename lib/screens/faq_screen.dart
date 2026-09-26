import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'How to apply for transport service?',
        'a':
            'Login to the app, go to "Apply Transport" module, fill the form and submit. Admin will review.'
      },
      {
        'q': 'How to mark attendance on the bus?',
        'a':
            'After fee payment, go to "Attendance" module and scan the QR code displayed by the driver.'
      },
      {
        'q': 'How to get my transport card?',
        'a':
            'After payment verification, go to "My Card" module and generate your digital card.'
      },
      {
        'q': 'What to do if I lose an item on the bus?',
        'a': 'Use "Lost & Found" module to post details. Admin will review.'
      },
      {
        'q': 'How to send emergency SOS?',
        'a': 'Tap SOS button. Alert will be sent to admin and guardian.'
      },
      {
        'q': 'How to become a driver?',
        'a':
            'Use "Driver Registration" module. Admin will verify and approve.'
      },
      {
        'q': 'How to check application status?',
        'a': 'Go to "Profile" screen. Status and payment info shown there.'
      },
      {
        'q': 'How to update guardian info?',
        'a': 'Go to "Profile" screen, Guardian Information section.'
      },
      {
        'q': 'How to change password?',
        'a': 'Go to "Profile" screen, Security section.'
      },
      {
        'q': 'How to contact support?',
        'a':
            'Email admin@campusmove.com or call university transport office.'
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: Text(faqs[i]['q']!,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(faqs[i]['a']!))
            ],
          ),
        ),
      ),
    );
  }
}