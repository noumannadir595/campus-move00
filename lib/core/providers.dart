import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeProvider() {
    _loadTheme();
  }
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;
  void setUserData(Map<String, dynamic>? data) {
    _userData = data;
    notifyListeners();
  }
}

class AnnouncementProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _unreadAnnouncements = [];
  List<Map<String, dynamic>> get unreadAnnouncements => _unreadAnnouncements;

  Future<void> loadUnreadAnnouncements() async {
    final snapshot =
        await getDatabase().ref('announcements').orderByChild('timestamp').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final all = data.entries
          .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
          .toList();
      all.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      final prefs = await SharedPreferences.getInstance();
      final List<String> readIds =
          prefs.getStringList('read_announcements') ?? [];
      _unreadAnnouncements =
          all.where((a) => !readIds.contains(a['id'])).toList();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readIds = prefs.getStringList('read_announcements') ?? [];
    if (!readIds.contains(announcementId)) {
      readIds.add(announcementId);
      await prefs.setStringList('read_announcements', readIds);
      _unreadAnnouncements.removeWhere((a) => a['id'] == announcementId);
      notifyListeners();
    }
  }
}