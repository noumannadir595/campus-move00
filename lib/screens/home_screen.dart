import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers.dart';
import '../widgets/hover_3d_card.dart';
import 'admin_login_screen.dart';
import 'apply_transport_screen.dart';
import 'developer_info_screen.dart';
import 'driver_signup_screen.dart';
import 'emergency_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';
import 'live_tracking_screen.dart';
import 'login_screen.dart';
import 'lost_found_screen.dart';
import 'profile_screen.dart';
import 'routes_screen.dart';
import 'sos_screen.dart';
import 'student_attendance_screen.dart';
import 'transport_card_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '☀️ Good Morning!';
    if (hour < 16) return '🌸 Good Afternoon!';
    if (hour < 20) return '🌙 Good Evening!';
    return '🌃 Good Night!';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: Colors.white),
            SizedBox(width: 8),
            Text('Campus Move')
          ],
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.blue, Colors.purple]))),
        actions: [
          IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode),
              onPressed: () => themeProvider.toggleTheme()),
          IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()))),
          if (user != null)
            IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          if (user == null)
            IconButton(
                icon: const Icon(Icons.login),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bus_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.blue.shade900)),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_getGreeting(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _build3DModuleCard(
                          'Routes',
                          Icons.route,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RoutesScreen()))),
                      _build3DModuleCard(
                          'Emergency',
                          Icons.emergency,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EmergencyScreen()))),
                      _build3DModuleCard(
                          'Apply Transport', Icons.directions_bus, () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ApplyTransportScreen()));
                        }
                      }),
                      _build3DModuleCard('My Card', Icons.credit_card, () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TransportCardScreen()));
                        }
                      }),
                      _build3DModuleCard(
                          'Feedback',
                          Icons.feedback,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FeedbackScreen()))),
                      _build3DModuleCard(
                          'Developer Info',
                          Icons.info,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const DeveloperInfoScreen()))),
                      _build3DModuleCard(
                          'Live Tracking',
                          Icons.map,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LiveTrackingScreen()))),
                      _build3DModuleCard(
                          'Lost & Found',
                          Icons.search,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LostFoundScreen()))),
                      _build3DModuleCard('Attendance', Icons.qr_code_scanner,
                          () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const StudentAttendanceScreen()));
                        }
                      }),
                      _build3DModuleCard(
                          'FAQs',
                          Icons.question_answer,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FAQScreen()))),
                      _build3DModuleCard(
                          'Driver',
                          Icons.drive_eta,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DriverSignupScreen()))),
                      _build3DModuleCard(
                          'SOS',
                          Icons.warning,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SOSScreen()))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DModuleCard(String title, IconData icon, VoidCallback onTap) {
    return Hover3DCard(
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.blue),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login or sign up to access this feature.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
