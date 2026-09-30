import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database.dart';
import '../core/providers.dart';
import '../theme.dart';
import '../widgets/module_card.dart';
import 'admin_login_screen.dart';
import 'apply_transport_screen.dart';
import 'auth_screen.dart';
import 'developer_info_screen.dart';
import 'driver_signup_screen.dart';
import 'emergency_screen.dart';
import 'faq_screen.dart';
import 'feedback_screen.dart';
import 'live_tracking_screen.dart';
import 'lost_found_screen.dart';
import 'profile_screen.dart';
import 'routes_screen.dart';
import 'sos_screen.dart';
import 'student_attendance_screen.dart';
import 'transport_card_screen.dart';
import 'transport_fees_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _announcementController = ScrollController();
  Timer? _scrollTimer;
  List<Map<String, dynamic>> _announcements = [];
  bool _announcementsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final snap = await getDatabase()
          .ref('announcements')
          .orderByChild('timestamp')
          .limitToLast(5)
          .get();
      if (snap.exists && mounted) {
        final data = snap.value as Map<dynamic, dynamic>;
        final list = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        list.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        setState(() {
          _announcements = list;
          _announcementsLoaded = true;
        });
        _startScrolling();
      } else {
        if (mounted) setState(() => _announcementsLoaded = true);
      }
    } catch (_) {
      if (mounted) setState(() => _announcementsLoaded = true);
    }
  }

  void _startScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_announcementController.hasClients) {
        final maxScroll = _announcementController.position.maxScrollExtent;
        final currentScroll = _announcementController.offset;
        if (currentScroll >= maxScroll) {
          _announcementController.jumpTo(0);
        } else {
          _announcementController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text('Campus Move'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/bus_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: AppColors.primaryDark),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                if (_announcementsLoaded && _announcements.isNotEmpty)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.campaign_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'NEWS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _announcementController,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: _announcements.map((a) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 30),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle,
                                            size: 6, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          a['title'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        ModuleCard(
                          title: 'Routes',
                          icon: Icons.route_rounded,
                          gradient: AppColors.routeGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RoutesScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Emergency',
                          icon: Icons.emergency_rounded,
                          gradient: AppColors.emergencyGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EmergencyScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Apply Transport',
                          icon: Icons.directions_bus_rounded,
                          gradient: AppColors.applyGradient,
                          onTap: () {
                            if (user == null) {
                              _showLoginRequired(context);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ApplyTransportScreen()),
                              );
                            }
                          },
                        ),
                        ModuleCard(
                          title: 'My Card',
                          icon: Icons.credit_card_rounded,
                          gradient: AppColors.cardGradient,
                          onTap: () {
                            if (user == null) {
                              _showLoginRequired(context);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const TransportCardScreen()),
                              );
                            }
                          },
                        ),
                        // ==================== TRANSPORT FEES (NEW) ====================
                        ModuleCard(
                          title: 'Transport Fees',
                          icon: Icons.receipt_long_rounded,
                          gradient: AppColors.faqGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TransportFeesScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: user == null ? 'Login / Signup' : 'My Profile',
                          icon: user == null
                              ? Icons.login_rounded
                              : Icons.person_rounded,
                          gradient: user == null
                              ? AppColors.loginGradient
                              : AppColors.profileGradient,
                          onTap: () {
                            if (user == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfileScreen()),
                              );
                            }
                          },
                        ),
                        ModuleCard(
                          title: 'Feedback',
                          icon: Icons.feedback_rounded,
                          gradient: AppColors.feedbackGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeedbackScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Developer Info',
                          icon: Icons.info_rounded,
                          gradient: AppColors.developerGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DeveloperInfoScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Live Tracking',
                          icon: Icons.map_rounded,
                          gradient: AppColors.trackingGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LiveTrackingScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Lost & Found',
                          icon: Icons.search_rounded,
                          gradient: AppColors.lostfoundGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LostFoundScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Attendance',
                          icon: Icons.qr_code_scanner_rounded,
                          gradient: AppColors.attendanceGradient,
                          onTap: () {
                            if (user == null) {
                              _showLoginRequired(context);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const StudentAttendanceScreen()),
                              );
                            }
                          },
                        ),
                        ModuleCard(
                          title: 'FAQs',
                          icon: Icons.question_answer_rounded,
                          gradient: AppColors.faqGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FAQScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'Driver',
                          icon: Icons.drive_eta_rounded,
                          gradient: AppColors.driverGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DriverSignupScreen()),
                          ),
                        ),
                        ModuleCard(
                          title: 'SOS',
                          icon: Icons.warning_rounded,
                          gradient: AppColors.sosGradient,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SOSScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please login or sign up to access this feature.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}