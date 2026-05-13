import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';

// ==================== NOTIFICATIONS ====================
final FlutterLocalNotificationsPlugin notifPlugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await notifPlugin.initialize(settings);
}

Future<void> showReminder(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminders', 'Campus Move Reminders',
    importance: Importance.high, priority: Priority.high,
  );
  const NotificationDetails details = NotificationDetails(android: androidDetails);
  await notifPlugin.show(0, title, body, details);
}

// ==================== DATABASE ====================
FirebaseDatabase getDatabase() {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://campus-move00-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}

// ==================== MAIN ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initNotifications();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ==================== PROVIDERS ====================
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeProvider() { _loadTheme(); }
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
    final snapshot = await getDatabase().ref('announcements').orderByChild('timestamp').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final all = data.entries
          .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
          .toList();
      all.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      final prefs = await SharedPreferences.getInstance();
      final List<String> readIds = prefs.getStringList('read_announcements') ?? [];
      _unreadAnnouncements = all.where((a) => !readIds.contains(a['id'])).toList();
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

// ==================== MY APP ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Campus Move',
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.blue, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue, useMaterial3: true),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeWrapper()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/comsats_logo.png', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 100, color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Campus Move', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('COMSATS University Sahiwal', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

// ==================== HOME WRAPPER ====================
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
              final provider = Provider.of<AnnouncementProvider>(context, listen: false);
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
                  final userData = Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                  Provider.of<UserProvider>(context, listen: false).setUserData(userData);
                  if (userData['role'] == 'admin') {
                    return const AdminDashboardWrapper();
                  }
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

// ==================== HOVER 3D CARD ====================
class Hover3DCard extends StatefulWidget {
  final Widget child;
  const Hover3DCard({super.key, required this.child});
  @override
  State<Hover3DCard> createState() => _Hover3DCardState();
}
class _Hover3DCardState extends State<Hover3DCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.02 : 1.0,
        child: widget.child,
      ),
    );
  }
}

// ==================== COMING SOON SCREEN ====================
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
            Text('🚧 Coming Soon 🚧', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('This feature will be available in the next update.'),
          ],
        ),
      ),
    );
  }
}

// ==================== LOST & FOUND SCREEN ====================
// ==================== LOST & FOUND SCREEN (FIXED) ====================
// ==================== LOST & FOUND SCREEN (FINAL FIXED) ====================
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});
  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}
class _LostFoundScreenState extends State<LostFoundScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  String _selectedType = 'Lost';
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final snap = await getDatabase().ref('lostfound').orderByChild('timestamp').get();
      if (snap.exists && mounted) {
        final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
        setState(() {
          _items = data.entries
              .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
              .toList();
          _items.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isUploading = true);
        final ref = FirebaseStorage.instance
            .ref()
            .child('lostfound/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking/uploading image: $e')),
      );
    }
  }

  Future<void> _postItem() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post')),
      );
      setState(() => _isUploading = false);
      return;
    }

    try {
      String userName = 'User';
      final userSnap = await getDatabase().ref('users/${user.uid}').get();
      if (userSnap.exists) {
        userName = (userSnap.value as Map)['name'] ?? 'User';
      }

      await getDatabase().ref('lostfound').push().set({
        'type': _selectedType,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'imageUrl': _imageUrl ?? '',
        'userId': user.uid,
        'userName': userName,
        'timestamp': ServerValue.timestamp,
      });

      // Clear form
      _titleCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
      _contactCtrl.clear();
      setState(() {
        _imageUrl = null;
        _isUploading = false;
      });

      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posted successfully!')),
        );
        Navigator.pop(context); // close bottom sheet
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting: $e')),
      );
    }
  }

  Future<void> _deleteItem(String id) async {
    await getDatabase().ref('lostfound/$id').remove();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user != null &&
        Provider.of<UserProvider>(context).userData?['role'] == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPostDialog(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No posts yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final item = _items[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item['imageUrl'] != null &&
                              item['imageUrl'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  child: Image.network(item['imageUrl']),
                                ),
                              ),
                              child: Image.network(
                                item['imageUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item['type'] == 'Lost'
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item['type'],
                                        style: TextStyle(
                                          color: item['type'] == 'Lost'
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['title'],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isAdmin || item['userId'] == user?.uid)
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () => _deleteItem(item['id']),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('📍 ${item['location']}'),
                                Text('📝 ${item['description']}'),
                                const SizedBox(height: 8),
                                Text(
                                  '📞 ${item['contact']}',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                                Text(
                                  '👤 ${item['userName']}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '📅 ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(item['timestamp']))}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showPostDialog() {
    // Reset image for new post
    _imageUrl = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Post Lost/Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                      DropdownMenuItem(value: 'Found', child: Text('Found')),
                    ],
                    onChanged: (v) {
                      setStateSB(() => _selectedType = v!);
                    },
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(labelText: 'Contact Number'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(_imageUrl != null ? 'Image Added' : 'Add Image'),
                        ),
                      ),
                      if (_imageUrl != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() => _imageUrl = null);
                            setStateSB(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _postItem,
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : const Text('Post'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
// ==================== HOME SCREEN (With Greeting) ====================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good Morning!';
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
        title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.directions_bus, color: Colors.white), SizedBox(width: 8), Text('Campus Move')]),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple]))),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
          ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          if (user == null)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bus_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.blue.shade900)),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getGreeting(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _build3DModuleCard('Routes', Icons.route, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutesScreen()))),
                      _build3DModuleCard('Emergency', Icons.emergency, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen()))),
                      _build3DModuleCard('Apply Transport', Icons.directions_bus, () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyTransportScreen()));
                        }
                      }),
                      _build3DModuleCard('My Card', Icons.credit_card, () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TransportCardScreen()));
                        }
                      }),
                      _build3DModuleCard('Feedback', Icons.feedback, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
                      _build3DModuleCard('Developer Info', Icons.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperInfoScreen()))),
                      _build3DModuleCard('Live Tracking', Icons.map, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen(feature: 'Live Tracking')))),
                      _build3DModuleCard('Lost & Found', Icons.search, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen()))),
                      _build3DModuleCard('Attendance', Icons.qr_code_scanner, () {
                        if (user == null) {
                          _showLoginRequired(context);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()));
                        }
                      }),
                      _build3DModuleCard('Help & Support', Icons.help, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()))),
                      _build3DModuleCard('Multiple Routes', Icons.route, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultipleRoutesScreen()))),
                      _build3DModuleCard('SOS', Icons.warning, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSScreen()))),
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
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// ==================== MULTIPLE ROUTES SCREEN ====================
class MultipleRoutesScreen extends StatefulWidget {
  const MultipleRoutesScreen({super.key});
  @override
  State<MultipleRoutesScreen> createState() => _MultipleRoutesScreenState();
}
class _MultipleRoutesScreenState extends State<MultipleRoutesScreen> {
  List<String> _availableRoutes = [];
  List<String> _selectedRoutes = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _loadUserRoutes();
  }
  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _availableRoutes = data.entries.map((e) => e.value['name'] as String).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  Future<void> _loadUserRoutes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await getDatabase().ref('userRoutes/$uid').get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _selectedRoutes = data.values.map((e) => e as String).toList();
      });
    }
  }
  Future<void> _saveRoutes() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = getDatabase().ref('userRoutes/$uid');
    await ref.remove();
    for (var route in _selectedRoutes) {
      await ref.push().set(route);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routes saved successfully')));
    if (mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Multiple Routes'),
        actions: [TextButton(onPressed: _saveRoutes, child: const Text('Save'))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _availableRoutes.length,
              itemBuilder: (ctx, i) {
                final route = _availableRoutes[i];
                final isSelected = _selectedRoutes.contains(route);
                return CheckboxListTile(
                  title: Text(route),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedRoutes.add(route);
                      } else {
                        _selectedRoutes.remove(route);
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}

// ==================== SOS SCREEN ====================
class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});
  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  bool _sending = false;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await getDatabase().ref('users/${user.uid}').get();
      if (snap.exists && mounted) {
        setState(() {
          _userName = (snap.value as Map)['name'] ?? 'Student';
        });
      }
    }
  }

  Future<void> _sendSOS() async {
    if (_sending) return;
    setState(() => _sending = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      setState(() => _sending = false);
      return;
    }

    try {
      // Store SOS for admin
      await getDatabase().ref('sosAlerts').push().set({
        'userId': user.uid,
        'userName': _userName,
        'timestamp': ServerValue.timestamp,
        'status': 'active',
      });

      // Send to Ntfy – no custom headers, only plain text body
      const String topic = 'campus_move_emergency_123'; // exact same as subscribed
      final url = Uri.parse('https://ntfy.sh/$topic');
      
      final response = await http.post(
        url,
        body: '''
EMERGENCY SOS - Campus Move

Student Name: $_userName
Time: ${DateTime.now()}
Please call immediately.
''',
      );

      if (response.statusCode == 200) {
        showReminder('SOS Sent', 'Emergency alert sent to guardian & admin.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS sent! Guardian notified.')),
        );
      } else {
        throw Exception('Ntfy error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text('Tap button to send emergency alert', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Notifying: campus_move_emergency_123', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _sending ? null : _sendSOS,
              icon: const Icon(Icons.sos, size: 30),
              label: const Text('SEND SOS', style: TextStyle(fontSize: 24)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            if (_sending) const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
// ==================== ADMIN DASHBOARD WRAPPER ====================
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
                final userData = Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                if (userData['role'] == 'admin') {
                  return const AdminDashboardHome();
                } else {
                  FirebaseAuth.instance.signOut();
                }
              }
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard('Pending Apps', Icons.pending_actions, Colors.orange,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingAppsScreen()))),
            _buildAdminCard('All Apps', Icons.list_alt, Colors.blue,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAppsScreen()))),
            _buildAdminCard('Users', Icons.people, Colors.green,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()))),
            _buildAdminCard('Feedback', Icons.feedback, Colors.purple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()))),
            _buildAdminCard('Routes', Icons.route, Colors.teal,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutesManagementScreen()))),
            _buildAdminCard('Emergency', Icons.emergency, Colors.red,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyManagementScreen()))),
            _buildAdminCard('Announcements', Icons.announcement, Colors.deepPurple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsManagementScreen()))),
            _buildAdminCard('Attendance', Icons.qr_code, Colors.indigo,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()))),
            _buildAdminCard('Driver QR', Icons.qr_code_scanner, Colors.deepOrange,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverQRGeneratorScreen()))),
            _buildAdminCard('Lost & Found', Icons.search, Colors.brown,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen()))),
            _buildAdminCard('Feedback Analytics', Icons.bar_chart, Colors.cyan,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackAnalyticsScreen()))),
            _buildAdminCard('Monthly Report', Icons.receipt, Colors.blueGrey,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen()))),
            _buildAdminCard('SOS Alerts', Icons.warning, Colors.redAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSAlertsScreen()))),
            _buildAdminCard('Driver Location', Icons.location_on, Colors.green,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverLocationScreen()))),
          ],
        ),
      ),
    );
  }
  Widget _buildAdminCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==================== FEEDBACK ANALYTICS SCREEN ====================
class FeedbackAnalyticsScreen extends StatefulWidget {
  const FeedbackAnalyticsScreen({super.key});
  @override
  State<FeedbackAnalyticsScreen> createState() => _FeedbackAnalyticsScreenState();
}
class _FeedbackAnalyticsScreenState extends State<FeedbackAnalyticsScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _loadFeedbacks(); }
  Future<void> _loadFeedbacks() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('feedbacks').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _feedbacks = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final positive = _feedbacks.where((f) => f['comment'].toString().toLowerCase().contains('good') || f['comment'].toString().toLowerCase().contains('nice')).length;
    final negative = _feedbacks.length - positive;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Feedback Sentiment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: positive.toDouble(), title: 'Positive ($positive)', color: Colors.green, radius: 60),
                    PieChartSectionData(value: negative.toDouble(), title: 'Negative ($negative)', color: Colors.red, radius: 60),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _feedbacks.length,
                itemBuilder: (ctx, i) => Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(_feedbacks[i]['name']),
                    subtitle: Text(_feedbacks[i]['comment']),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MONTHLY REPORT SCREEN (PDF) ====================
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});
  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}
class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<Map<String, dynamic>> _attendance = [];
  bool _loading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  @override
  void initState() { super.initState(); _loadAttendance(); }
  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('attendance').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _attendance = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final filtered = _attendance.where((a) {
      final date = DateTime.fromMillisecondsSinceEpoch(a['timestamp']);
      return DateFormat('yyyy-MM').format(date) == _selectedMonth;
    }).toList();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Monthly Attendance Report - $_selectedMonth')),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [pw.Text('Student Name'), pw.Text('Route'), pw.Text('Date')]),
              ...filtered.map((a) => pw.TableRow(children: [
                pw.Text(a['studentName']),
                pw.Text(a['route']),
                pw.Text(DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(a['timestamp']))),
              ])),
            ],
          ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'attendance_$_selectedMonth.pdf');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _generatePDF)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Select Month: '),
                Expanded(
                  child: TextFormField(
                    initialValue: _selectedMonth,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedMonth = DateFormat('yyyy-MM').format(date);
                          _loadAttendance();
                        });
                      }
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _attendance.where((a) => DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) == _selectedMonth).length,
                    itemBuilder: (ctx, i) {
                      final filtered = _attendance.where((a) => DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) == _selectedMonth).toList();
                      final a = filtered[i];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(a['studentName']),
                          subtitle: Text('Route: ${a['route']} | ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(a['timestamp']))}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== SOS ALERTS SCREEN (ADMIN) ====================
class SOSAlertsScreen extends StatefulWidget {
  const SOSAlertsScreen({super.key});
  @override
  State<SOSAlertsScreen> createState() => _SOSAlertsScreenState();
}
class _SOSAlertsScreenState extends State<SOSAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _loadAlerts(); }
  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('sosAlerts').orderByChild('timestamp').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _alerts = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _alerts.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  Future<void> _resolveAlert(String id) async {
    await getDatabase().ref('sosAlerts/$id').update({'status': 'resolved'});
    _loadAlerts();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (ctx, i) {
                final alert = _alerts[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  color: alert['status'] == 'active' ? Colors.red.shade50 : Colors.grey.shade200,
                  child: ListTile(
                    title: Text(alert['userName']),
                    subtitle: Text('Time: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(alert['timestamp']))}\nStatus: ${alert['status']}'),
                    trailing: alert['status'] == 'active'
                        ? ElevatedButton(onPressed: () => _resolveAlert(alert['id']), child: const Text('Resolve'))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// ==================== DRIVER LOCATION SCREEN (Admin) ====================
class DriverLocationScreen extends StatefulWidget {
  const DriverLocationScreen({super.key});
  @override
  State<DriverLocationScreen> createState() => _DriverLocationScreenState();
}
class _DriverLocationScreenState extends State<DriverLocationScreen> {
  Map<String, dynamic>? _busLocation;
  bool _loading = true;
  @override
  void initState() { super.initState(); _loadLocation(); }
  Future<void> _loadLocation() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('busLocation').get();
    if (snap.exists) {
      setState(() {
        _busLocation = Map<String, dynamic>.from(snap.value as Map);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Live Location')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _busLocation == null
              ? const Center(child: Text('No location data available'))
              : Center(
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_bus, size: 60, color: Colors.blue),
                          const SizedBox(height: 16),
                          const Text('Current Location:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Latitude: ${_busLocation!['latitude']}', style: const TextStyle(fontSize: 16)),
                          Text('Longitude: ${_busLocation!['longitude']}', style: const TextStyle(fontSize: 16)),
                          Text('Last Updated: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(_busLocation!['timestamp']))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              final url = 'https://www.google.com/maps/search/?api=1&query=${_busLocation!['latitude']},${_busLocation!['longitude']}';
                              launchUrl(Uri.parse(url));
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('View on Map'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ==================== DRIVER LOCATION UPDATE SCREEN (for driver) ====================
class DriverLocationUpdateScreen extends StatefulWidget {
  const DriverLocationUpdateScreen({super.key});
  @override
  State<DriverLocationUpdateScreen> createState() => _DriverLocationUpdateScreenState();
}
class _DriverLocationUpdateScreenState extends State<DriverLocationUpdateScreen> {
  final TextEditingController _latCtrl = TextEditingController();
  final TextEditingController _lngCtrl = TextEditingController();
  Future<void> _updateLocation() async {
    if (_latCtrl.text.isEmpty || _lngCtrl.text.isEmpty) return;
    await getDatabase().ref('busLocation').set({
      'latitude': double.parse(_latCtrl.text.trim()),
      'longitude': double.parse(_lngCtrl.text.trim()),
      'timestamp': ServerValue.timestamp,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated')));
      _latCtrl.clear();
      _lngCtrl.clear();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Bus Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _updateLocation, child: const Text('Update Location')),
          ],
        ),
      ),
    );
  }
}

// ==================== ANNOUNCEMENTS MANAGEMENT ====================
class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});
  @override
  State<AnnouncementsManagementScreen> createState() => _AnnouncementsManagementScreenState();
}
class _AnnouncementsManagementScreenState extends State<AnnouncementsManagementScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('announcements').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _announcements = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  Future<void> _post() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    await getDatabase().ref('announcements').push().set({
      'title': _titleCtrl.text.trim(),
      'message': _msgCtrl.text.trim(),
      'timestamp': ServerValue.timestamp,
    });
    _titleCtrl.clear();
    _msgCtrl.clear();
    _load();
  }
  Future<void> _delete(String id) async {
    await getDatabase().ref('announcements/$id').remove();
    _load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _post, child: const Text('Post Announcement')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _announcements.length,
                    itemBuilder: (ctx, i) {
                      final a = _announcements[i];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(a['title']),
                          subtitle: Text(a['message']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(a['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== ATTENDANCE SYSTEM ====================
class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});
  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}
class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('attendance').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _attendanceRecords = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _attendanceRecords.length,
              itemBuilder: (ctx, i) {
                final rec = _attendanceRecords[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('Student: ${rec['studentName']}'),
                    subtitle: Text('Route: ${rec['route']} | Date: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(rec['timestamp']))}'),
                  ),
                );
              },
            ),
    );
  }
}

class DriverQRGeneratorScreen extends StatefulWidget {
  const DriverQRGeneratorScreen({super.key});
  @override
  State<DriverQRGeneratorScreen> createState() => _DriverQRGeneratorScreenState();
}
class _DriverQRGeneratorScreenState extends State<DriverQRGeneratorScreen> {
  String _selectedRoute = '';
  List<String> _routes = [];
  String? _qrData;
  @override
  void initState() { super.initState(); _loadRoutes(); }
  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _routes = data.entries.map((e) => e.value['name'] as String).toList();
      });
    }
  }
  void _generateQR() {
    if (_selectedRoute.isEmpty) return;
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final qrContent = 'CAMPUS_MOVE_ATTENDANCE|$sessionId|$_selectedRoute|${DateTime.now().toIso8601String()}';
    setState(() => _qrData = qrContent);
    getDatabase().ref('attendanceSessions/$sessionId').set({
      'route': _selectedRoute,
      'expiry': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Attendance QR')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedRoute.isEmpty ? null : _selectedRoute,
              hint: const Text('Select Route'),
              items: _routes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRoute = v!),
              decoration: const InputDecoration(labelText: 'Route', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _generateQR, child: const Text('Generate QR Code')),
            const SizedBox(height: 30),
            if (_qrData != null) ...[
              QrImageView(data: _qrData!, size: 200),
              const SizedBox(height: 10),
              const Text('Valid for 1 hour', style: TextStyle(color: Colors.green)),
            ],
          ],
        ),
      ),
    );
  }
}

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}
class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isScanning = false;
  String _result = '';
  final MobileScannerController scannerController = MobileScannerController();

  Future<bool> _checkPaymentStatus() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists && snap.value != null) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        final app = data.values.first;
        if (app['paymentStatus'] == 'paid') return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanning) return;
    // Payment check
    final isPaid = await _checkPaymentStatus();
    if (!isPaid) {
      if (mounted) {
        setState(() => _result = '⚠️ Please complete fee payment first to mark attendance.');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _result = '');
        });
      }
      return;
    }
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.startsWith('CAMPUS_MOVE_ATTENDANCE|')) {
      if (mounted) setState(() { _isScanning = true; _result = 'Processing...'; });
      final parts = code.split('|');
      if (parts.length >= 4) {
        final sessionId = parts[1];
        final route = parts[2];
        final sessionSnap = await getDatabase().ref('attendanceSessions/$sessionId').get();
        if (!sessionSnap.exists) {
          _result = 'Invalid or expired QR code.';
        } else {
          final expiryMap = sessionSnap.value as Map<dynamic, dynamic>;
          if (DateTime.now().millisecondsSinceEpoch > (expiryMap['expiry'] as int)) {
            _result = 'QR code expired.';
          } else {
            final user = FirebaseAuth.instance.currentUser!;
            final userSnap = await getDatabase().ref('users/${user.uid}').get();
            final studentName = (userSnap.value as Map<dynamic, dynamic>)['name'] as String;
            await getDatabase().ref('attendance').push().set({
              'studentId': user.uid,
              'studentName': studentName,
              'route': route,
              'timestamp': ServerValue.timestamp,
              'date': DateTime.now().toIso8601String(),
            });
            _result = 'Attendance marked for route $route!';
            showReminder('Attendance Marked', 'You have marked attendance for $route');
          }
        }
      } else {
        _result = 'Invalid QR code.';
      }
      if (mounted) {
        setState(() { _isScanning = false; });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _result = '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(controller: scannerController, onDetect: _onDetect),
          ),
          Expanded(
            child: Center(child: Text(_result, style: const TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }
}

// ==================== HELP & SUPPORT ====================
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}
class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  void _sendMessage() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': _msgCtrl.text.trim()});
      _msgCtrl.clear();
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({'sender': 'support', 'text': 'Thank you for contacting support. Our team will respond soon.'});
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[_messages.length - 1 - i];
                return Align(
                  alignment: msg['sender'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg['sender'] == 'user' ? Colors.blue.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _msgCtrl, decoration: const InputDecoration(hintText: 'Type your question...')),
                ),
                IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PROFILE SCREEN (with guardian and change password) ====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profilePicUrl;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _transportCard;
  String? _errorMessage;
  final TextEditingController _guardianNameCtrl = TextEditingController();
  final TextEditingController _guardianPhoneCtrl = TextEditingController();
  final TextEditingController _newPasswordCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadAll(); }
  Future<void> _refreshData() async { setState(() => _isLoading = true); await _loadAll(); }
  Future<void> _loadAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { setState(() { _errorMessage = 'Not logged in'; _isLoading = false; }); return; }
      final uid = user.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (!userSnap.exists) { setState(() { _errorMessage = 'User data not found'; _isLoading = false; }); return; }
      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      _guardianNameCtrl.text = userData['guardianName'] ?? '';
      _guardianPhoneCtrl.text = userData['guardianPhone'] ?? '';
      final appSnap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
      Map<String, dynamic>? appData;
      if (appSnap.exists && appSnap.value != null) {
        final apps = appSnap.value as Map<dynamic, dynamic>;
        if (apps.isNotEmpty) appData = Map<String, dynamic>.from(apps.values.first);
      }
      final cardSnap = await getDatabase().ref('transportCards').orderByChild('userId').equalTo(uid).get();
      Map<String, dynamic>? cardData;
      if (cardSnap.exists && cardSnap.value != null) {
        final cards = cardSnap.value as Map<dynamic, dynamic>;
        if (cards.isNotEmpty) cardData = Map<String, dynamic>.from(cards.values.first);
      }
      if (mounted) {
        setState(() {
          _userData = userData; _profilePicUrl = userData['profilePic']; _application = appData; _transportCard = cardData; _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Error: $e'; _isLoading = false; });
    }
  }
  Future<void> _updateProfilePic() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child('profilePics/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await getDatabase().ref('users/$uid').update({'profilePic': url});
      if (mounted) setState(() => _profilePicUrl = url);
    }
  }
  Future<void> _updateGuardian() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await getDatabase().ref('users/$uid').update({
      'guardianName': _guardianNameCtrl.text.trim(),
      'guardianPhone': _guardianPhoneCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardian info updated')));
    }
  }
  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    if (newPass.isEmpty) return;
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
        _newPasswordCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
  Future<void> _downloadChallan(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open file')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  Future<void> _logout() async { await FirebaseAuth.instance.signOut(); if (mounted) Navigator.pop(context); }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _refreshData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData, tooltip: 'Refresh'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profilePicUrl != null ? NetworkImage(_profilePicUrl!) : null,
                  child: _profilePicUrl == null ? const Icon(Icons.person, size: 50) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      onPressed: _updateProfilePic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.person), title: const Text('Name'), subtitle: Text(_userData!['name'])),
          ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(_userData!['email'])),
          ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(_userData!['phone'])),
          ListTile(leading: const Icon(Icons.business), title: const Text('Department'), subtitle: Text(_userData!['department'])),
          const Divider(),
          const Text('Guardian Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _guardianNameCtrl, decoration: const InputDecoration(labelText: 'Guardian Name', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _guardianPhoneCtrl, decoration: const InputDecoration(labelText: 'Guardian Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _updateGuardian, child: const Text('Save Guardian Info')),
          const Divider(),
          const Text('Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(controller: _newPasswordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _changePassword, child: const Text('Change Password')),
          const Divider(),
          const Text('Application Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_application != null) ...[
            ListTile(title: Text('Route: ${_application!['route']}'), subtitle: Text('Status: ${_application!['status']} | Payment: ${_application!['paymentStatus'] ?? 'Pending'}')),
            if (_application!['status'] == 'approved' && _application!['challanUrl'] != null)
              ElevatedButton.icon(onPressed: () => _downloadChallan(_application!['challanUrl']), icon: const Icon(Icons.download), label: const Text('Download Challan')),
            if (_application!['paymentStatus'] == 'pending')
              ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallanViewScreen())), child: const Text('Upload Payment Proof')),
          ] else const Text('No application submitted yet.'),
          const Divider(),
          const Text('Transport Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (_transportCard != null) ...[
            Card(color: Colors.blue.shade100, child: ListTile(title: Text('Card #: ${_transportCard!['cardNumber']}'), subtitle: Text('Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_transportCard!['expiry']))}'))),
          ] else const Text('Card not generated yet.'),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout', style: TextStyle(color: Colors.red)), onTap: _logout),
        ],
      ),
    );
  }
}

// ==================== PENDING APPS ====================
class PendingAppsScreen extends StatefulWidget {
  const PendingAppsScreen({super.key});
  @override
  State<PendingAppsScreen> createState() => _PendingAppsScreenState();
}
class _PendingAppsScreenState extends State<PendingAppsScreen> {
  List<Map<String, dynamic>> _pendingApps = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadPendingApps(); }

  Future<void> _loadPendingApps() async {
    setState(() => _isLoading = true);
    final appsSnap = await getDatabase().ref('applications').get();
    if (appsSnap.exists && mounted) {
      final apps = appsSnap.value as Map<dynamic, dynamic>;
      final allApps = apps.entries
          .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
          .toList();
      setState(() {
        _pendingApps = allApps.where((a) => a['status'] == 'pending').toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveApplication(String appKey) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Uploading challan...')],
        ),
      ),
    );

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension ?? 'file';
      final fileName = 'challan_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = FirebaseStorage.instance.ref().child('challans/$fileName');

      // Upload file
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Update database
      await getDatabase().ref('applications/$appKey').update({
        'status': 'approved',
        'challanUrl': downloadUrl,
        'paymentStatus': 'pending',
      });

      // Send notification to user
      final appSnap = await getDatabase().ref('applications/$appKey').get();
      final appData = appSnap.value as Map<dynamic, dynamic>;
      final userId = appData['userId'] as String;
      final userSnap = await getDatabase().ref('users/$userId').get();
      final userEmail = (userSnap.value as Map<dynamic, dynamic>)['email'] as String;
      showReminder('Application Approved', 'Your transport application has been approved. Please download challan and upload payment proof.');

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application approved & challan uploaded')),
        );
        _loadPendingApps();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e. Check Storage rules and network.')),
      );
    }
  }

  Future<void> _rejectApplication(String appKey) async {
    await getDatabase().ref('applications/$appKey').update({'status': 'rejected'});
    showReminder('Application Rejected', 'Your transport application has been rejected.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected')));
      _loadPendingApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingApps.isEmpty
              ? const Center(child: Text('No pending applications'))
              : ListView.builder(
                  itemCount: _pendingApps.length,
                  itemBuilder: (ctx, i) {
                    final app = _pendingApps[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(app['name']),
                        subtitle: Text('Route: ${app['route']} | Type: ${app['userType']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📧 Email: ${app['email']}'),
                                Text('📞 Phone: ${app['phone']}'),
                                Text('🏛 Department: ${app['department']}'),
                                Text('🆔 ${app['userType'] == 'student' ? 'Registration' : 'University ID'}: ${app['regId']}'),
                                Text('📅 Submitted: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(app['submittedAt'] ?? 0))}'),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _approveApplication(app['id']),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () => _rejectApplication(app['id']),
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
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
// ==================== ALL APPS ====================
class AllAppsScreen extends StatefulWidget {
  const AllAppsScreen({super.key});
  @override
  State<AllAppsScreen> createState() => _AllAppsScreenState();
}
class _AllAppsScreenState extends State<AllAppsScreen> {
  List<Map<String, dynamic>> _allApps = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadAllApps(); }
  Future<void> _loadAllApps() async {
    setState(() => _isLoading = true);
    final appsSnap = await getDatabase().ref('applications').get();
    if (appsSnap.exists && mounted) {
      final apps = appsSnap.value as Map<dynamic, dynamic>;
      setState(() { _allApps = apps.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _verifyPayment(String appKey) async {
    await getDatabase().ref('applications/$appKey').update({'paymentStatus': 'paid'});
    showReminder('Payment Verified', 'Your payment has been verified. You can now generate your transport card and mark attendance.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified')));
      _loadAllApps();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allApps.length,
              itemBuilder: (ctx, i) {
                final app = _allApps[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(app['name']),
                    subtitle: Text('Status: ${app['status']} | Payment: ${app['paymentStatus'] ?? 'N/A'}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📧 Email: ${app['email']}'),
                            Text('📞 Phone: ${app['phone']}'),
                            Text('🏛 Department: ${app['department']}'),
                            Text('🆔 ID: ${app['regId']}'),
                            Text('🚌 Route: ${app['route']}'),
                            if (app['paymentStatus'] == 'proof_uploaded')
                              ElevatedButton(onPressed: () => _verifyPayment(app['id']), child: const Text('Verify Payment')),
                          ],
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

// ==================== USERS ====================
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}
class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadUsers(); }
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final usersSnap = await getDatabase().ref('users').get();
    if (usersSnap.exists && mounted) {
      final users = usersSnap.value as Map<dynamic, dynamic>;
      setState(() { _users = users.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_users[i]['name']),
                  subtitle: Text('${_users[i]['email']} | ${_users[i]['userType']} | Role: ${_users[i]['role']}'),
                  isThreeLine: true,
                ),
              ),
            ),
    );
  }
}

// ==================== ADMIN FEEDBACK ====================
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});
  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}
class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadFeedbacks(); }
  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    final feedbackSnap = await getDatabase().ref('feedbacks').get();
    if (feedbackSnap.exists && mounted) {
      final feedbacks = feedbackSnap.value as Map<dynamic, dynamic>;
      setState(() { _feedbacks = feedbacks.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Feedback')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _feedbacks.length,
              itemBuilder: (ctx, i) => Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.orange),
                  title: Text(_feedbacks[i]['name']),
                  subtitle: Text('Email: ${_feedbacks[i]['email']}\nComment: ${_feedbacks[i]['comment']}'),
                  isThreeLine: true,
                ),
              ),
            ),
    );
  }
}

// ==================== ROUTES MANAGEMENT ====================
class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});
  @override
  State<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}
class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadRoutes(); }
  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    final snapshot = await getDatabase().ref('routes').get();
    if (snapshot.exists && mounted) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() { _routes = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _addEditRoute({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final stopsCtrl = TextEditingController(text: existing?['stops']);
    final timingCtrl = TextEditingController(text: existing?['timing']);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Route' : 'Edit Route'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name')),
            TextField(controller: stopsCtrl, decoration: const InputDecoration(labelText: 'Stops')),
            TextField(controller: timingCtrl, decoration: const InputDecoration(labelText: 'Timing')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final data = {
        'name': nameCtrl.text.trim(),
        'stops': stopsCtrl.text.trim(),
        'timing': timingCtrl.text.trim(),
      };
      if (existing != null) {
        await getDatabase().ref('routes/${existing['id']}').update(data);
      } else {
        await getDatabase().ref('routes').push().set(data);
      }
      _loadRoutes();
    }
  }
  Future<void> _deleteRoute(String id) async {
    await getDatabase().ref('routes/$id').remove();
    _loadRoutes();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routes'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addEditRoute())],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (ctx, i) {
                final route = _routes[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(route['name']),
                    subtitle: Text('Timing: ${route['timing']}\nStops: ${route['stops']}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _addEditRoute(existing: route)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteRoute(route['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== EMERGENCY MANAGEMENT ====================
class EmergencyManagementScreen extends StatefulWidget {
  const EmergencyManagementScreen({super.key});
  @override
  State<EmergencyManagementScreen> createState() => _EmergencyManagementScreenState();
}
class _EmergencyManagementScreenState extends State<EmergencyManagementScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadContacts(); }
  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final snapshot = await getDatabase().ref('emergencyContacts').get();
    if (snapshot.exists && mounted) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() { _contacts = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList(); _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _addEditContact({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final numberCtrl = TextEditingController(text: existing?['number']);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final data = {
        'name': nameCtrl.text.trim(),
        'number': numberCtrl.text.trim(),
      };
      if (existing != null) {
        await getDatabase().ref('emergencyContacts/${existing['id']}').update(data);
      } else {
        await getDatabase().ref('emergencyContacts').push().set(data);
      }
      _loadContacts();
    }
  }
  Future<void> _deleteContact(String id) async {
    await getDatabase().ref('emergencyContacts/$id').remove();
    _loadContacts();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addEditContact())],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (ctx, i) {
                final contact = _contacts[i];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.emergency, color: Colors.red),
                    title: Text(contact['name']),
                    subtitle: Text(contact['number']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _addEditContact(existing: contact)),
                        IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteContact(contact['id'])),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== ADMIN LOGIN ====================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}
class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser!;
      final snapshot = await getDatabase().ref('users/${user.uid}').get();
      if (snapshot.exists && (snapshot.value as Map)['role'] == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardWrapper()));
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authorized')));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 60, color: Colors.blue),
                    const Text('Admin Access', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    TextField(controller: _emailController, decoration: _inputDecoration('Admin Email', Icons.email)),
                    const SizedBox(height: 16),
                    TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration('Password', Icons.lock)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Login as Admin', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  }
}

// ==================== ADMIN PROFILE ====================
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}
class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _newPasswordController = TextEditingController();
  Map<String, dynamic>? _userData;
  @override
  void initState() { super.initState(); _loadUserData(); }
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final snapshot = await getDatabase().ref('users/${user.uid}').get();
    if (snapshot.exists && mounted) {
      setState(() => _userData = Map<String, dynamic>.from(snapshot.value as Map));
    }
  }
  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isEmpty) return;
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
        _newPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.admin_panel_settings, size: 50)),
            const SizedBox(height: 20),
            Text('Name: ${_userData!['name']}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            const Text('Role: Admin', style: TextStyle(fontSize: 16, color: Colors.blue)),
            const Divider(height: 40),
            TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _updatePassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Update Password')),
          ],
        ),
      ),
    );
  }
}

// ==================== FEEDBACK ====================
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}
class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSending = false;
  Future<void> _sendFeedback() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    setState(() => _isSending = true);
    await getDatabase().ref('feedbacks').push().set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'comment': _commentController.text.trim(),
      'timestamp': ServerValue.timestamp,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you!')));
      Navigator.pop(context);
    }
    setState(() => _isSending = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Your Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _commentController, maxLines: 5, decoration: const InputDecoration(labelText: 'Comment', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
              child: _isSending ? const CircularProgressIndicator() : const Text('Send Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== LOGIN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.directions_bus, size: 60, color: Colors.blue),
                    const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    TextField(controller: _emailController, decoration: _inputDecoration('Email', Icons.email)),
                    const SizedBox(height: 16),
                    TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration('Password', Icons.lock)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: const Text("Don't have an account? Sign Up"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  }
}

// ==================== SIGNUP ====================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}
class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _regIdController = TextEditingController();
  String _userType = 'student';
  bool _isLoading = false;
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 10) return 'Invalid phone';
    return null;
  }
  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }
    if (_userType == 'student' && _regIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration number required')));
      return;
    }
    if (_userType == 'faculty' && _regIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('University ID required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final role = _emailController.text.trim() == 'admin@campusmove.com' ? 'admin' : 'user';
      final userData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'userType': _userType,
        'role': role,
        'department': _departmentController.text.trim(),
        'createdAt': ServerValue.timestamp,
      };
      if (_userType == 'student') {
        userData['registrationNumber'] = _regIdController.text.trim();
      } else {
        userData['universityId'] = _regIdController.text.trim();
      }
      await getDatabase().ref('users/${userCred.user!.uid}').set(userData);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), backgroundColor: Colors.transparent),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(controller: _nameController, decoration: _inputDecoration('Full Name', Icons.person)),
                    const SizedBox(height: 12),
                    TextField(controller: _emailController, decoration: _inputDecoration('Email', Icons.email)),
                    const SizedBox(height: 12),
                    TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration('Password', Icons.lock)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _phoneController, decoration: _inputDecoration('Phone Number', Icons.phone), validator: _validatePhone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    TextField(controller: _departmentController, decoration: _inputDecoration('Department', Icons.business)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _userType,
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                      ],
                      onChanged: (val) => setState(() => _userType = val!),
                      decoration: _inputDecoration('I am a', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _regIdController, decoration: _inputDecoration(_userType == 'student' ? 'Registration Number' : 'University ID', Icons.badge)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
  }
}

// ==================== ROUTES (USER) ====================
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}
class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _routes = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Routes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _routes.length,
              itemBuilder: (ctx, i) {
                final route = _routes[i];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: ExpansionTile(
                    leading: const Icon(Icons.directions_bus, color: Colors.blue),
                    title: Text(route['name']),
                    subtitle: Text('⏰ ${route['timing']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('🛑 Stops: ${route['stops']}', style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ==================== EMERGENCY (USER) ====================
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}
class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadContacts();
  }
  Future<void> _loadContacts() async {
    final snap = await getDatabase().ref('emergencyContacts').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _contacts = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _contacts.length,
              itemBuilder: (ctx, i) {
                final contact = _contacts[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.contact_emergency, color: Colors.red),
                    title: Text(contact['name']),
                    subtitle: Text(contact['number']),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: Colors.blue),
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling ${contact['number']}...')),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== APPLY TRANSPORT ====================
class ApplyTransportScreen extends StatefulWidget {
  const ApplyTransportScreen({super.key});
  @override
  State<ApplyTransportScreen> createState() => _ApplyTransportScreenState();
}
class _ApplyTransportScreenState extends State<ApplyTransportScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _regIdController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRoute = '';
  List<String> _routesList = [];
  bool _hasApplied = false;
  Map<String, dynamic>? _existingApplication;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRoutes();
    _checkExistingApplication();
  }
  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('users/$uid').get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _departmentController.text = data['department'] ?? '';
      if (data['userType'] == 'student') {
        _regIdController.text = data['registrationNumber'] ?? '';
      } else {
        _regIdController.text = data['universityId'] ?? '';
      }
      setState(() {});
    }
  }
  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _routesList = data.entries.map((e) => e.value['name'] as String).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _checkExistingApplication() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        setState(() {
          _hasApplied = true;
          _existingApplication = Map<String, dynamic>.from(data.values.first);
        });
      }
    }
  }
  Future<void> _submitApplication() async {
    if (_selectedRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select route')));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userSnap = await getDatabase().ref('users/$uid').get();
    final userData = Map<String, dynamic>.from(userSnap.value as Map);
    await getDatabase().ref('applications').push().set({
      'userId': uid,
      'name': userData['name'],
      'userType': userData['userType'],
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'department': _departmentController.text.trim(),
      'regId': _regIdController.text.trim(),
      'route': _selectedRoute,
      'status': 'pending',
      'submittedAt': ServerValue.timestamp,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted!')));
      _checkExistingApplication();
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_hasApplied && _existingApplication != null) {
      final status = _existingApplication!['status'];
      return Scaffold(
        appBar: AppBar(title: const Text('Transport Application')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'approved'
                        ? Icons.check_circle
                        : (status == 'rejected' ? Icons.cancel : Icons.pending),
                    size: 64,
                    color: status == 'approved' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text('Status: $status', style: const TextStyle(fontSize: 20)),
                  if (status == 'approved' && _existingApplication!['challanUrl'] != null)
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChallanViewScreen()),
                      ),
                      child: const Text('View Challan'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Transport')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    decoration: _inputDecoration('Phone Number', Icons.phone),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration('Email', Icons.email),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _regIdController,
                    decoration: _inputDecoration('Registration / University ID', Icons.badge),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _departmentController,
                    decoration: _inputDecoration('Department', Icons.business),
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoute.isEmpty ? null : _selectedRoute,
                    hint: const Text('Select Route'),
                    items: _routesList.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setState(() => _selectedRoute = v!),
                    decoration: _inputDecoration('Route', Icons.route),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Submit Application'),
                  ),
                ],
              ),
            ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ==================== CHALLAN VIEW ====================
class ChallanViewScreen extends StatefulWidget {
  const ChallanViewScreen({super.key});
  @override
  State<ChallanViewScreen> createState() => _ChallanViewScreenState();
}
class _ChallanViewScreenState extends State<ChallanViewScreen> {
  Map<String, dynamic>? _challanData;
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    _fetchChallan();
  }
  Future<void> _fetchChallan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        final app = data.values.first;
        if (app['challanUrl'] != null) {
          setState(() {
            _challanData = {
              'url': app['challanUrl'],
              'status': app['paymentStatus'] ?? 'pending'
            };
          });
        }
      }
    }
  }
  Future<void> _uploadPaidProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isUploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        final appKey = data.keys.first;
        final ref = FirebaseStorage.instance.ref().child('proofs/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(picked.path));
        final proofUrl = await ref.getDownloadURL();
        await getDatabase().ref('applications/$appKey').update({
          'paidProofUrl': proofUrl,
          'paymentStatus': 'proof_uploaded',
        });
      }
    }
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof uploaded, waiting for admin verification.')),
      );
      showReminder('Payment Proof Submitted', 'Your payment proof is under review.');
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_challanData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Challan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text('Admin Issued Challan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                Text('Challan URL: ${_challanData!['url']}'),
                const SizedBox(height: 16),
                if (_challanData!['status'] == 'pending')
                  ElevatedButton.icon(
                    onPressed: _uploadPaidProof,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Paid Proof'),
                  ),
                if (_isUploading) const CircularProgressIndicator(),
                if (_challanData!['status'] == 'proof_uploaded')
                  const Text('Proof uploaded, admin will verify soon.'),
                if (_challanData!['status'] == 'paid')
                  const Text('Payment verified! You can now generate card.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TRANSPORT CARD ====================
class TransportCardScreen extends StatefulWidget {
  const TransportCardScreen({super.key});
  @override
  State<TransportCardScreen> createState() => _TransportCardScreenState();
}
class _TransportCardScreenState extends State<TransportCardScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _cardData;
  Future<void> _generateCard() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (_emailController.text.trim() != user.email) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email mismatch')));
      return;
    }
    if (_passwordController.text.trim() != user.email) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password')));
      return;
    }
    setState(() => _isLoading = true);
    final uid = user.uid;
    final appSnap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (!appSnap.exists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No application')));
      setState(() => _isLoading = false);
      return;
    }
    final apps = appSnap.value as Map<dynamic, dynamic>;
    if (apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No application')));
      setState(() => _isLoading = false);
      return;
    }
    final app = apps.values.first;
    if (app['paymentStatus'] != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment not verified yet.')));
      setState(() => _isLoading = false);
      return;
    }
    final cardSnap = await getDatabase().ref('transportCards').orderByChild('userId').equalTo(uid).get();
    if (cardSnap.exists && cardSnap.value != null) {
      final cards = cardSnap.value as Map<dynamic, dynamic>;
      if (cards.isNotEmpty) {
        setState(() {
          _cardData = Map<String, dynamic>.from(cards.values.first);
          _isLoading = false;
        });
        return;
      }
    }
    final cardNumber = 'CM-${DateTime.now().millisecondsSinceEpoch}';
    final newCardRef = getDatabase().ref('transportCards').push();
    await newCardRef.set({
      'userId': uid,
      'cardNumber': cardNumber,
      'issueDate': ServerValue.timestamp,
      'expiry': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
      'valid': true,
    });
    final snap = await newCardRef.get();
    setState(() {
      _cardData = Map<String, dynamic>.from(snap.value as Map);
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_cardData != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Transport Card')),
        body: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            margin: const EdgeInsets.all(24),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.credit_card, size: 60, color: Colors.white),
                  const Text('Campus Move', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('Card #: ${_cardData!['cardNumber']}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  Text(
                    'Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_cardData!['expiry']))}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.qr_code_scanner, size: 80, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Transport Card')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Your Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password (use email as password)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateCard,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Generate Card'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DEVELOPER INFO ====================
class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final developers = [
      {'name': 'Hafsa Saleem', 'role': 'Lecturer at CUI', 'image': 'assets/dev1.PNG', 'email': 'hafsasaleem@gmail.com', 'phone': 'Nil'},
      {'name': 'Nouman Nadir', 'role': ' Developer', 'image': 'assets/dev2.jpeg', 'email': 'noumannadir595@gmail.com', 'phone': '+92 325 9869056'},
      {'name': 'Aqsa', 'role': ' Developer', 'image': 'assets/dev3.jpeg', 'email': 'aqsaqamar0499@gmail.com', 'phone': 'Nil'},
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(dev['image']!),
                    onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dev['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(dev['role']!, style: const TextStyle(color: Colors.blue)),
                        const SizedBox(height: 4),
                        Text('Email: ${dev['email']}', style: const TextStyle(fontSize: 12)),
                        Text('Phone: ${dev['phone']}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}