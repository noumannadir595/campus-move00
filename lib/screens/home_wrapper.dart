import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/database.dart';
import '../core/providers.dart';
import 'admin_dashboard.dart';
import 'driver_home_screen.dart';
import 'home_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});
  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAnnouncements();
  }

  Future<void> _checkAnnouncements() async {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    await provider.loadUnreadAnnouncements();
    if (mounted && provider.unreadAnnouncements.isNotEmpty) {
      _showAnnouncementDialog(provider.unreadAnnouncements.first);
    }
  }

  void _showAnnouncementDialog(Map<String, dynamic> announcement) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(announcement['title'] ?? 'Announcement'),
        content: Text(announcement['message'] ?? ''),
        actions: [
          TextButton(
            onPressed: () async {
              await Provider.of<AnnouncementProvider>(context, listen: false)
                  .markAsRead(announcement['id']);
              if (mounted) Navigator.pop(ctx);
              final provider =
                  Provider.of<AnnouncementProvider>(context, listen: false);
              if (mounted && provider.unreadAnnouncements.isNotEmpty) {
                _showAnnouncementDialog(provider.unreadAnnouncements.first);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            return FutureBuilder<DataSnapshot>(
              future: getDatabase().ref('users/${user.uid}').get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.done &&
                    userSnapshot.hasData &&
                    userSnapshot.data!.exists) {
                  final userData =
                      Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                  Provider.of<UserProvider>(context, listen: false)
                      .setUserData(userData);
                  final role = userData['role'];
                  if (role == 'admin') return const AdminDashboardWrapper();
                  if (role == 'driver') return const DriverHomeScreen();
                }
                return const HomeScreen();
              },
            );
          }
        }
        return const HomeScreen();
      },
    );
  }
}