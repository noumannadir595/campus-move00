import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';
import 'admin_attendance_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_profile_screen.dart';
import 'all_apps_screen.dart';
import 'announcements_management_screen.dart';
import 'driver_applications_screen.dart';
import 'emergency_management_screen.dart';
import 'feedback_analytics_screen.dart';
import 'login_screen.dart';
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
          if (user == null) return const LoginScreen();
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

class AdminDashboardHome extends StatelessWidget {
  const AdminDashboardHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminProfileScreen()))),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
                'Driver Applications',
                Icons.drive_eta,
                Colors.orange,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const DriverApplicationsScreen()))),
            _buildAdminCard(
                'Pending Apps',
                Icons.pending_actions,
                Colors.orange,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PendingAppsScreen()))),
            _buildAdminCard(
                'All Apps',
                Icons.list_alt,
                Colors.blue,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AllAppsScreen()))),
            _buildAdminCard(
                'Users',
                Icons.people,
                Colors.green,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UsersScreen()))),
            _buildAdminCard(
                'Feedback',
                Icons.feedback,
                Colors.purple,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminFeedbackScreen()))),
            _buildAdminCard(
                'Routes',
                Icons.route,
                Colors.teal,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RoutesManagementScreen()))),
            _buildAdminCard(
                'Emergency',
                Icons.emergency,
                Colors.red,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EmergencyManagementScreen()))),
            _buildAdminCard(
                'Announcements',
                Icons.announcement,
                Colors.deepPurple,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const AnnouncementsManagementScreen()))),
            _buildAdminCard(
                'Attendance',
                Icons.qr_code,
                Colors.indigo,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAttendanceScreen()))),
            _buildAdminCard(
                'Lost & Found',
                Icons.search,
                Colors.brown,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LostFoundScreen()))),
            _buildAdminCard(
                'Feedback Analytics',
                Icons.bar_chart,
                Colors.cyan,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FeedbackAnalyticsScreen()))),
            _buildAdminCard(
                'Monthly Report',
                Icons.receipt,
                Colors.blueGrey,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MonthlyReportScreen()))),
            _buildAdminCard(
                'SOS Alerts',
                Icons.warning,
                Colors.redAccent,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SOSAlertsScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 6,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}