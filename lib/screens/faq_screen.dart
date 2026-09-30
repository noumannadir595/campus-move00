import 'package:flutter/material.dart';

import '../theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'How do I create an account?',
        'a':
            'Tap "Login / Signup" on the home screen. Choose Student or Faculty tab. Enter your name, email, phone number and password, then tap Sign Up.'
      },
      {
        'q': 'Which email can I use to sign up?',
        'a':
            'Students: FA22-BSE-038@students.cuisahiwal.edu.pk\n\nFaculty: name@cuisahiwal.edu.pk'
      },
      {
        'q': 'I forgot my password. What should I do?',
        'a':
            'On the Login screen, enter your email and tap "Forgot Password?". A reset link will be sent to your email. Open the link and set a new password.'
      },
      {
        'q': 'How do I apply for transport?',
        'a':
            'Go to Home → "Apply Transport". Your information will be auto-filled. Just select your route and tap Submit.'
      },
      {
        'q': 'How do I get my fee challan?',
        'a':
            'After applying, go to "Transport Fees" or "Profile" screen. You will find the option to view and download the challan PDF there.'
      },
      {
        'q': 'How do I pay the transport fee?',
        'a':
            '1. Print the challan\n2. Submit it at any bank\n3. Show the paid challan at the Transport Desk\n4. Admin will verify it'
      },
      {
        'q': 'How long does approval take?',
        'a': 'It usually takes 2-3 working days.'
      },
      {
        'q': 'How do I check my application status?',
        'a':
            'Go to Home → "Apply Transport" or "Profile" screen. Your status will be shown there — Processing / Approved / Rejected.'
      },
      {
        'q': 'How do I get my transport card?',
        'a':
            'After your application is approved, the admin will upload your card. Go to Home → "My Card" to view it.'
      },
      {
        'q': 'How do I mark attendance on the bus?',
        'a':
            'Go to Home → "Attendance". The camera will open. Scan the QR code shown by the driver. You will get a confirmation message.'
      },
      {
        'q': 'How do I track my bus live?',
        'a':
            'Go to Home → "Live Tracking". Active routes will appear at the top (green). Tap Direction A or B to see the bus on the map.'
      },
      {
        'q': 'How do I post a lost or found item?',
        'a':
            'Go to Home → "Lost & Found". Tap "Add Post". Choose Lost or Found. Enter the details and add an image. Tap POST.'
      },
      {
        'q': 'How do I use SOS?',
        'a':
            'Go to Home → "SOS". Tap the big red button. An emergency alert will be sent to the admin and your guardian.'
      },
      {
        'q': 'How do I change my profile picture?',
        'a':
            'On the "Profile" screen, tap the camera icon. Choose an image from the gallery. It will be updated automatically.'
      },
      {
        'q': 'How do I contact support?',
        'a':
            'Email: admin@campusmove.com\n\nOr send a message through the "Feedback" module.\n\nOr visit the Transport Office.'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (ctx, i) {
          final faq = faqs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: const Icon(
                Icons.help_outline,
                color: AppColors.primary,
              ),
              title: Text(
                faq['q']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq['a']!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}