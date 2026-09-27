import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import '../theme.dart';
import 'admin_attendance_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_profile_screen.dart';
import 'all_apps_screen.dart';
import 'announcements_management_screen.dart';
import 'auth_screen.dart';
import 'driver_applications_screen.dart';
import 'emergency_management_screen.dart';
import 'feedback_analytics_screen.dart';
import 'lost_found_screen.dart';
import 'monthly_report_screen.dart';
import 'pending_apps_screen.dart';
import 'routes_management_screen.dart';
import 'sos_alerts_screen.dart';
import 'users_screen.dart';

class AdminDashboardWrapper extends StatefulWidget {
  const AdminDashboardWrapper({super.key});
  @override
  State<AdminDashboardWrapper> createState() => _AdminDashboardWrapperState();
}

class _AdminDashboardWrapperState extends State<AdminDashboardWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) return const AuthScreen();
          return FutureBuilder<DataSnapshot>(
            future: getDatabase().ref('users/${user.uid}').get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.done &&
                  userSnapshot.hasData &&
                  userSnapshot.data!.exists) {
                final userData =
                    Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                if (userData['role'] == 'admin') {
                  return const AdminDashboardHome();
                } else {
                  FirebaseAuth.instance.signOut();
                }
              }
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            },
          );
        }
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class AdminDashboardHome extends StatefulWidget {
  const AdminDashboardHome({super.key});
  @override
  State<AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<AdminDashboardHome> {
  int _totalUsers = 0;
  int _totalApplications = 0;
  int _totalDrivers = 0;
  int _totalRoutes = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final usersSnap = await getDatabase().ref('users').get();
      final appsSnap = await getDatabase().ref('applications').get();
      final routesSnap = await getDatabase().ref('routes').get();

      int users = 0, drivers = 0;
      if (usersSnap.exists) {
        final data = usersSnap.value as Map<dynamic, dynamic>;
        users = data.length;
        for (var u in data.values) {
          if (u['role'] == 'driver') drivers++;
        }
      }

      int apps = 0;
      if (appsSnap.exists) {
        apps = (appsSnap.value as Map).length;
      }

      int routes = 0;
      if (routesSnap.exists) {
        routes = (routesSnap.value as Map).length;
      }

      if (!mounted) return;
      setState(() {
        _totalUsers = users;
        _totalDrivers = drivers;
        _totalApplications = apps;
        _totalRoutes = routes;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==================== STATS CARDS ====================
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _statCard('Users', _totalUsers, Icons.people,
                            Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _statCard('Drivers', _totalDrivers,
                            Icons.drive_eta, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _statCard('Applications', _totalApplications,
                            Icons.assignment, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _statCard('Routes', _totalRoutes,
                            Icons.route, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // ==================== CHART ====================
                const Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'System Distribution',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _totalUsers.toDouble(),
                                  title: '$_totalUsers',
                                  color: Colors.blue,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: _totalApplications.toDouble(),
                                  title: '$_totalApplications',
                                  color: Colors.green,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: _totalRoutes.toDouble(),
                                  title: '$_totalRoutes',
                                  color: Colors.purple,
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legend('Users', Colors.blue),
                            const SizedBox(width: 16),
                            _legend('Apps', Colors.green),
                            const SizedBox(width: 16),
                            _legend('Routes', Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== QUICK ACTIONS ====================
                const Text(
                  'Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _adminCard('Driver Apps', Icons.drive_eta, Colors.orange,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const DriverApplicationsScreen()))),
                    _adminCard('Pending Apps', Icons.pending_actions,
                        Colors.amber, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PendingAppsScreen()))),
                    _adminCard('All Apps', Icons.list_alt, Colors.blue,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AllAppsScreen()))),
                    _adminCard('Users', Icons.people, Colors.green,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const UsersScreen()))),
                    _adminCard('Feedback', Icons.feedback, Colors.purple,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()))),
                    _adminCard('Routes', Icons.route, Colors.teal,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RoutesManagementScreen()))),
                    _adminCard('Emergency', Icons.emergency, Colors.red,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const EmergencyManagementScreen()))),
                    _adminCard('Announcements', Icons.announcement,
                        Colors.deepPurple, () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AnnouncementsManagementScreen()))),
                    _adminCard('Attendance', Icons.qr_code, Colors.indigo,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()))),
                    _adminCard('Lost & Found', Icons.search, Colors.brown,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LostFoundScreen()))),
                    _adminCard('Analytics', Icons.bar_chart, Colors.cyan,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FeedbackAnalyticsScreen()))),
                    _adminCard('Report', Icons.receipt, Colors.blueGrey,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const MonthlyReportScreen()))),
                    _adminCard('SOS', Icons.warning, Colors.redAccent,
                        () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SOSAlertsScreen()))),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _adminCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}