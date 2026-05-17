
import 'dart:io';
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
import 'package:http/http.dart' as http;
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()));
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

// ==================== WELCOME SCREEN ====================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeWrapper()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 100, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'Welcome to Campus Move',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Your Safe & Reliable Transport Partner',
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
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
              await Provider.of<AnnouncementProvider>(context, listen: false).markAsRead(announcement['id']);
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

// ==================== FAQ SCREEN ====================
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {'q': 'How to apply for transport service?', 'a': 'Login to the app, go to "Apply Transport" module, fill the form and submit. Admin will review.'},
      {'q': 'How to mark attendance on the bus?', 'a': 'After fee payment, go to "Attendance" module and scan the QR code displayed by the driver.'},
      {'q': 'How to get my transport card?', 'a': 'After payment verification, go to "My Card" module and generate your digital card.'},
      {'q': 'What to do if I lose an item on the bus?', 'a': 'Use "Lost & Found" module to post details. Admin will review.'},
      {'q': 'How to send emergency SOS?', 'a': 'Tap SOS button. Alert will be sent to admin and guardian.'},
      {'q': 'How to become a driver?', 'a': 'Use "Driver Registration" module. Admin will verify and approve.'},
      {'q': 'How to check application status?', 'a': 'Go to "Profile" screen. Status and payment info shown there.'},
      {'q': 'How to update guardian info?', 'a': 'Go to "Profile" screen, Guardian Information section.'},
      {'q': 'How to change password?', 'a': 'Go to "Profile" screen, Security section.'},
      {'q': 'How to contact support?', 'a': 'Email admin@campusmove.com or call university transport office.'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: faqs.length,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: Text(faqs[i]['q']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            children: [Padding(padding: const EdgeInsets.all(16), child: Text(faqs[i]['a']!))],
          ),
        ),
      ),
    );
  }
}

// ==================== LOST & FOUND SCREEN ====================
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
  void initState() { super.initState(); _loadItems(); }
  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('lostfound').orderByChild('timestamp').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _items = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _items.sort((a,b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        _loading = false;
      });
    } else { setState(() => _loading = false); }
  }
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isUploading = true);
        final ref = FirebaseStorage.instance.ref().child('lostfound/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        setState(() { _imageUrl = url; _isUploading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully!')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  Future<void> _postItem() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty || _contactCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to post')));
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
      _titleCtrl.clear(); _descCtrl.clear(); _locationCtrl.clear(); _contactCtrl.clear();
      setState(() { _imageUrl = null; _isUploading = false; });
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Posted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error posting: $e')));
    }
  }
  Future<void> _deleteItem(String id) async {
    await getDatabase().ref('lostfound/$id').remove();
    _loadItems();
  }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = user != null && Provider.of<UserProvider>(context).userData?['role'] == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Lost & Found'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showPostDialog()),
      ]),
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
                          if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.network(item['imageUrl']))),
                              child: Image.network(item['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item['type'] == 'Lost' ? Colors.red.shade100 : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(item['type'], style: TextStyle(color: item['type'] == 'Lost' ? Colors.red : Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(item['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                    if (isAdmin || item['userId'] == user?.uid)
                                      IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => _deleteItem(item['id'])),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('📍 ${item['location']}'),
                                Text('📝 ${item['description']}'),
                                const SizedBox(height: 8),
                                Text('📞 ${item['contact']}', style: const TextStyle(color: Colors.blue)),
                                Text('👤 ${item['userName']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('📅 ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(item['timestamp']))}'),
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
    _imageUrl = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Post Lost/Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                  DropdownMenuItem(value: 'Found', child: Text('Found')),
                ],
                onChanged: (v) { setStateSB(() => _selectedType = v!); },
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Number')),
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
                child: _isUploading ? const CircularProgressIndicator() : const Text('Post'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== UPDATED DRIVER SIGNUP & LOGIN SCREEN (SINGLE SCREEN WITH TOGGLE) ====================
class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRouteId = '';
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoginMode = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final snap = await getDatabase().ref('routes').get();
      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        final loadedRoutes = data.entries.map((e) {
          final value = Map<dynamic, dynamic>.from(e.value);
          return {
            'id': e.key.toString(),
            'routeNumber': value['routeNumber']?.toString() ?? '',
            'name': value['name']?.toString() ?? '',
          };
        }).toList();
        if (mounted) {
          setState(() {
            _routes = loadedRoutes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _selectedRouteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      await getDatabase().ref('driverApplications').push().set({
        'userId': cred.user!.uid,
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'routeId': _selectedRouteId,
        'status': 'pending',
        'timestamp': ServerValue.timestamp,
      });
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted. Admin will verify.')),
      );
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _selectedRouteId = '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser!;
      final uid = user.uid;
      bool isDriver = false;

      final userSnap = await getDatabase().ref('users/$uid').get();
      if (userSnap.exists && (userSnap.value as Map)['role'] == 'driver') {
        isDriver = true;
      }
      if (!isDriver) {
        final appSnap = await getDatabase()
            .ref('driverApplications')
            .orderByChild('userId')
            .equalTo(uid)
            .get();
        if (appSnap.exists) {
          final apps = appSnap.value as Map<dynamic, dynamic>;
          if (apps.isNotEmpty) {
            final app = apps.values.first;
            if (app['status'] == 'approved') {
              isDriver = true;
            } else {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your application is pending approval.')),
              );
              setState(() => _isSubmitting = false);
              return;
            }
          }
        }
      }
      if (isDriver) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No driver account found. Please register.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Driver Login' : 'Driver Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (!_isLoginMode) ...[
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 12),
                    TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRouteId.isEmpty ? null : _selectedRouteId,
                      hint: const Text('Select Route'),
                      items: _routes.map<DropdownMenuItem<String>>((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'] as String,
                          child: Text('Route ${r['routeNumber']}: ${r['name']}'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRouteId = v!),
                      decoration: const InputDecoration(labelText: 'Route'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : (_isLoginMode ? _login : _signup),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: _isSubmitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isLoginMode ? 'Login' : 'Submit Application'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLoginMode = !_isLoginMode;
                      _nameCtrl.clear();
                      _phoneCtrl.clear();
                      _selectedRouteId = '';
                      _emailCtrl.clear();
                      _passCtrl.clear();
                    }),
                    child: Text(_isLoginMode ? "Don't have an account? Register as Driver" : "Already have a driver account? Login"),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==================== DRIVER HOME SCREEN (for verified drivers) ====================
class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Map<String, dynamic>? _driverData;
  bool _loading = true;
  String? _routeNumber;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userSnap = await getDatabase().ref('users/$uid').get();
      if (userSnap.exists && (userSnap.value as Map)['role'] == 'driver') {
        setState(() {
          _driverData = Map<String, dynamic>.from(userSnap.value as Map);
          _loading = false;
        });
        await _loadRouteNumber();
        return;
      }
      final appSnap = await getDatabase()
          .ref('driverApplications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();
      if (appSnap.exists) {
        final apps = appSnap.value as Map<dynamic, dynamic>;
        if (apps.isNotEmpty) {
          final app = Map<String, dynamic>.from(apps.values.first);
          if (app['status'] == 'approved') {
            setState(() {
              _driverData = app;
              _loading = false;
            });
            await _loadRouteNumber();
            return;
          }
        }
      }
      setState(() {
        _driverData = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _driverData = null;
      });
    }
  }

  Future<void> _loadRouteNumber() async {
    if (_driverData == null) return;
    final routeId = _driverData?['routeId'] ?? _driverData?['assignedRoute'];
    if (routeId == null) return;
    final snap = await getDatabase().ref('routes/$routeId').get();
    if (snap.exists) {
      setState(() {
        _routeNumber = (snap.value as Map)['routeNumber']?.toString() ?? '';
      });
    }
  }

  void _generateQR() {
    if (_driverData == null) return;
    final routeId = _driverData?['routeId'] ?? _driverData?['assignedRoute'];
    if (routeId == null) return;
    final sessionId = DateTime.now().millisecondsSinceEpoch;
    final qrData = 'CAMPUS_MOVE_ATTENDANCE|$sessionId|$routeId|${DateTime.now().toIso8601String()}';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: qrData, size: 200),
              const SizedBox(height: 16),
              Text('Valid for 1 hour - Route ${_routeNumber ?? ''}'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
    getDatabase().ref('attendanceSessions/$sessionId').set({
      'route': routeId,
      'expiry': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_driverData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Your application is pending or rejected.'),
              Text('Please contact admin for approval.'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver - Route ${_routeNumber ?? ''}'),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text('Name: ${_driverData?['name'] ?? ''}'),
                subtitle: Text('Phone: ${_driverData?['phone'] ?? ''}'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate Attendance QR'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: Live location tracking will be available in the next update.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME SCREEN (User) ====================
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
          children: [Icon(Icons.directions_bus, color: Colors.white), SizedBox(width: 8), Text('Campus Move')],
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple]))),
        actions: [
          IconButton(icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: () => themeProvider.toggleTheme()),
          IconButton(icon: const Icon(Icons.admin_panel_settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()))),
          if (user != null)
            IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          if (user == null)
            IconButton(icon: const Icon(Icons.login), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/bus_bg.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.blue.shade900)),
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_getGreeting(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
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
                      _build3DModuleCard('FAQs', Icons.question_answer, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen()))),
                      _build3DModuleCard('Driver', Icons.drive_eta, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSignupScreen()))),
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

// ==================== ROUTES MANAGEMENT (Admin) ====================
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
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _routes = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _isLoading = false;
      });
    } else { setState(() => _isLoading = false); }
  }
  Future<void> _addEditRoute({Map<String, dynamic>? existing}) async {
    final routeNumCtrl = TextEditingController(text: existing?['routeNumber']);
    final nameCtrl = TextEditingController(text: existing?['name']);
    final stopsCtrl = TextEditingController(text: existing?['stops']);
    final driverCtrl = TextEditingController(text: existing?['driverName']);
    final assistantCtrl = TextEditingController(text: existing?['assistantName']);
    final conductorCtrl = TextEditingController(text: existing?['conductorName']);
    final driverPhoneCtrl = TextEditingController(text: existing?['driverPhone']);
    final assistantPhoneCtrl = TextEditingController(text: existing?['assistantPhone']);
    final conductorPhoneCtrl = TextEditingController(text: existing?['conductorPhone']);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Route' : 'Edit Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: routeNumCtrl, decoration: const InputDecoration(labelText: 'Route Number (e.g., 1)')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Route Name')),
              TextField(controller: stopsCtrl, decoration: const InputDecoration(labelText: 'Stops')),
              const Divider(),
              const Text('Staff Details', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              TextField(controller: driverPhoneCtrl, decoration: const InputDecoration(labelText: 'Driver Phone')),
              TextField(controller: assistantCtrl, decoration: const InputDecoration(labelText: 'Assistant Driver Name')),
              TextField(controller: assistantPhoneCtrl, decoration: const InputDecoration(labelText: 'Assistant Phone')),
              TextField(controller: conductorCtrl, decoration: const InputDecoration(labelText: 'Conductor Name')),
              TextField(controller: conductorPhoneCtrl, decoration: const InputDecoration(labelText: 'Conductor Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      final data = {
        'routeNumber': routeNumCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'stops': stopsCtrl.text.trim(),
        'driverName': driverCtrl.text.trim(),
        'driverPhone': driverPhoneCtrl.text.trim(),
        'assistantName': assistantCtrl.text.trim(),
        'assistantPhone': assistantPhoneCtrl.text.trim(),
        'conductorName': conductorCtrl.text.trim(),
        'conductorPhone': conductorPhoneCtrl.text.trim(),
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
                  child: ExpansionTile(
                    title: Text('Route ${route['routeNumber']}: ${route['name']}'),
                    subtitle: Text('Driver: ${route['driverName']}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Stops: ${route['stops']}'),
                            const Divider(),
                            Text('Driver: ${route['driverName']} (${route['driverPhone']})'),
                            Text('Assistant: ${route['assistantName']} (${route['assistantPhone']})'),
                            Text('Conductor: ${route['conductorName']} (${route['conductorPhone']})'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(icon: const Icon(Icons.edit), onPressed: () => _addEditRoute(existing: route)),
                                IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteRoute(route['id'])),
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
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard('Driver Applications', Icons.drive_eta, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverApplicationsScreen()))),
            _buildAdminCard('Pending Apps', Icons.pending_actions, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingAppsScreen()))),
            _buildAdminCard('All Apps', Icons.list_alt, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAppsScreen()))),
            _buildAdminCard('Users', Icons.people, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()))),
            _buildAdminCard('Feedback', Icons.feedback, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()))),
            _buildAdminCard('Routes', Icons.route, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutesManagementScreen()))),
            _buildAdminCard('Emergency', Icons.emergency, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyManagementScreen()))),
            _buildAdminCard('Announcements', Icons.announcement, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsManagementScreen()))),
            _buildAdminCard('Attendance', Icons.qr_code, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()))),
            _buildAdminCard('Lost & Found', Icons.search, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LostFoundScreen()))),
            _buildAdminCard('Feedback Analytics', Icons.bar_chart, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackAnalyticsScreen()))),
            _buildAdminCard('Monthly Report', Icons.receipt, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen()))),
            _buildAdminCard('SOS Alerts', Icons.warning, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSAlertsScreen()))),
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

// ==================== DRIVER APPLICATIONS SCREEN (Admin) ====================
class DriverApplicationsScreen extends StatefulWidget {
  const DriverApplicationsScreen({super.key});
  @override
  State<DriverApplicationsScreen> createState() => _DriverApplicationsScreenState();
}
class _DriverApplicationsScreenState extends State<DriverApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  @override
  void initState() { super.initState(); _loadApplications(); }
  Future<void> _loadApplications() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('driverApplications').orderByChild('status').equalTo('pending').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _applications = data.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
        _loading = false;
      });
    } else { setState(() => _loading = false); }
  }
  Future<void> _approve(String appId, String userId, String routeId, String name, String email, String phone) async {
    await getDatabase().ref('driverApplications/$appId').update({'status': 'approved'});
    final userData = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': 'driver',
      'userType': 'driver',
      'assignedRoute': routeId,
      'createdAt': ServerValue.timestamp,
    };
    await getDatabase().ref('users/$userId').set(userData);
    showReminder('Driver Application Approved', 'Your driver application has been approved. You can now login.');
    _loadApplications();
  }
  Future<void> _reject(String appId) async {
    await getDatabase().ref('driverApplications/$appId').update({'status': 'rejected'});
    _loadApplications();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Applications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(child: Text('No pending driver applications'))
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (ctx, i) {
                    final app = _applications[i];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(app['name']),
                        subtitle: Text('Email: ${app['email']}\nPhone: ${app['phone']}\nRoute ID: ${app['routeId']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approve(app['id'], app['userId'], app['routeId'], app['name'], app['email'], app['phone'])),
                            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _reject(app['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ==================== PENDING APPS SCREEN (Admin) ====================
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
      final allApps = apps.entries.map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)}).toList();
      setState(() {
        _pendingApps = allApps.where((a) => a['status'] == 'pending').toList();
        _isLoading = false;
      });
    } else { setState(() => _isLoading = false); }
  }
  Future<void> _approveApplication(String appKey) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Uploading challan...')])));
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null) { if (mounted) Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file selected'))); return; }
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension ?? 'file';
      final fileName = 'challan_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final ref = FirebaseStorage.instance.ref().child('challans/$fileName');
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      await getDatabase().ref('applications/$appKey').update({
        'status': 'approved',
        'challanUrl': downloadUrl,
        'paymentStatus': 'pending',
      });
      showReminder('Application Approved', 'Your transport application has been approved. Please download challan and upload payment proof.');
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application approved & challan uploaded'))); _loadPendingApps(); }
    } catch (e) { if (mounted) Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }
  Future<void> _rejectApplication(String appKey) async {
    await getDatabase().ref('applications/$appKey').update({'status': 'rejected'});
    showReminder('Application Rejected', 'Your transport application has been rejected.');
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rejected'))); _loadPendingApps(); }
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
                                    ElevatedButton.icon(onPressed: () => _approveApplication(app['id']), icon: const Icon(Icons.check), label: const Text('Approve'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(onPressed: () => _rejectApplication(app['id']), icon: const Icon(Icons.close), label: const Text('Reject'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
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

// ==================== ALL APPS SCREEN (Admin) ====================
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
    } else { setState(() => _isLoading = false); }
  }
  Future<void> _verifyPayment(String appKey) async {
    await getDatabase().ref('applications/$appKey').update({'paymentStatus': 'paid'});
    showReminder('Payment Verified', 'Your payment has been verified. You can now generate your transport card and mark attendance.');
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified'))); _loadAllApps(); }
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

// ==================== USERS SCREEN (Admin) ====================
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
    } else { setState(() => _isLoading = false); }
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

// ==================== ADMIN FEEDBACK SCREEN (Admin) ====================
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
    } else { setState(() => _isLoading = false); }
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

// ==================== EMERGENCY MANAGEMENT SCREEN (Admin) ====================
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
    } else { setState(() => _isLoading = false); }
  }
  Future<void> _addEditContact({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name']);
    final numberCtrl = TextEditingController(text: existing?['number']);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: numberCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))],
      ),
    );
    if (result == true) {
      final data = {'name': nameCtrl.text.trim(), 'number': numberCtrl.text.trim()};
      if (existing != null) {
        await getDatabase().ref('emergencyContacts/${existing['id']}').update(data);
      } else {
        await getDatabase().ref('emergencyContacts').push().set(data);
      }
      _loadContacts();
    }
  }
  Future<void> _deleteContact(String id) async { await getDatabase().ref('emergencyContacts/$id').remove(); _loadContacts(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _addEditContact())]),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _contacts.length,
        itemBuilder: (ctx, i) {
          final contact = _contacts[i];
          return Card(margin: const EdgeInsets.all(8), child: ListTile(
            leading: const Icon(Icons.emergency, color: Colors.red),
            title: Text(contact['name']), subtitle: Text(contact['number']),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _addEditContact(existing: contact)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteContact(contact['id'])),
            ]),
          ));
        },
      ),
    );
  }
}

// ==================== ANNOUNCEMENTS MANAGEMENT SCREEN (Admin) ====================
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
    } else { setState(() => _loading = false); }
  }
  Future<void> _post() async {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    await getDatabase().ref('announcements').push().set({
      'title': _titleCtrl.text.trim(),
      'message': _msgCtrl.text.trim(),
      'timestamp': ServerValue.timestamp,
    });
    _titleCtrl.clear(); _msgCtrl.clear(); _load();
  }
  Future<void> _delete(String id) async { await getDatabase().ref('announcements/$id').remove(); _load(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Announcements')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _post, child: const Text('Post Announcement')),
        ])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
          itemCount: _announcements.length,
          itemBuilder: (ctx, i) {
            final a = _announcements[i];
            return Card(margin: const EdgeInsets.all(8), child: ListTile(
              title: Text(a['title']), subtitle: Text(a['message']),
              trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(a['id'])),
            ));
          },
        )),
      ]),
    );
  }
}

// ==================== ADMIN ATTENDANCE SCREEN (Admin) ====================
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
    } else { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Records')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _attendanceRecords.length,
        itemBuilder: (ctx, i) {
          final rec = _attendanceRecords[i];
          return Card(margin: const EdgeInsets.all(8), child: ListTile(
            title: Text('Student: ${rec['studentName']}'),
            subtitle: Text('Route: ${rec['route']} | Date: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(rec['timestamp']))}'),
          ));
        },
      ),
    );
  }
}

// ==================== FEEDBACK ANALYTICS SCREEN (Admin) ====================
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
    } else { setState(() => _loading = false); }
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
            SizedBox(height: 200, child: PieChart(PieChartData(sections: [PieChartSectionData(value: positive.toDouble(), title: 'Positive ($positive)', color: Colors.green, radius: 60), PieChartSectionData(value: negative.toDouble(), title: 'Negative ($negative)', color: Colors.red, radius: 60)]))),
            const SizedBox(height: 20),
            const Text('Recent Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(child: ListView.builder(
              itemCount: _feedbacks.length,
              itemBuilder: (ctx, i) => Card(margin: const EdgeInsets.all(8), child: ListTile(title: Text(_feedbacks[i]['name']), subtitle: Text(_feedbacks[i]['comment']))),
            )),
          ],
        ),
      ),
    );
  }
}

// ==================== MONTHLY REPORT SCREEN (Admin) ====================
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
    } else { setState(() => _loading = false); }
  }
  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    final filtered = _attendance.where((a) => DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) == _selectedMonth).toList();
    pdf.addPage(pw.MultiPage(build: (context) => [
      pw.Header(level: 0, child: pw.Text('Monthly Attendance Report - $_selectedMonth')),
      pw.Table(border: pw.TableBorder.all(), children: [
        pw.TableRow(children: [pw.Text('Student Name'), pw.Text('Route'), pw.Text('Date')]),
        ...filtered.map((a) => pw.TableRow(children: [pw.Text(a['studentName']), pw.Text(a['route']), pw.Text(DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])))]))
      ])
    ]));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'attendance_$_selectedMonth.pdf');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report'), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _generatePDF)]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Text('Select Month: '),
          Expanded(child: TextFormField(initialValue: _selectedMonth, readOnly: true, onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (date != null) { setState(() { _selectedMonth = DateFormat('yyyy-MM').format(date); _loadAttendance(); }); }
          }, decoration: const InputDecoration(border: OutlineInputBorder()))),
        ])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
          itemCount: _attendance.where((a) => DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) == _selectedMonth).length,
          itemBuilder: (ctx, i) {
            final filtered = _attendance.where((a) => DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp'])) == _selectedMonth).toList();
            final a = filtered[i];
            return Card(margin: const EdgeInsets.all(8), child: ListTile(title: Text(a['studentName']), subtitle: Text('Route: ${a['route']} | ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(a['timestamp']))}')));
          },
        )),
      ]),
    );
  }
}

// ==================== SOS ALERTS SCREEN (Admin) ====================
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
        _alerts.sort((a,b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        _loading = false;
      });
    } else { setState(() => _loading = false); }
  }
  Future<void> _resolveAlert(String id) async {
    await getDatabase().ref('sosAlerts/$id').update({'status': 'resolved'});
    _loadAlerts();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Alerts')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _alerts.length,
        itemBuilder: (ctx, i) {
          final alert = _alerts[i];
          return Card(margin: const EdgeInsets.all(8), color: alert['status'] == 'active' ? Colors.red.shade50 : Colors.grey.shade200,
            child: ListTile(
              title: Text(alert['userName']),
              subtitle: Text('Time: ${DateFormat.yMMMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(alert['timestamp']))}\nStatus: ${alert['status']}'),
              trailing: alert['status'] == 'active' ? ElevatedButton(onPressed: () => _resolveAlert(alert['id']), child: const Text('Resolve')) : null,
            ),
          );
        },
      ),
    );
  }
}

// ==================== ADMIN LOGIN SCREEN ====================
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      final user = FirebaseAuth.instance.currentUser!;
      final snapshot = await getDatabase().ref('users/${user.uid}').get();
      if (snapshot.exists && (snapshot.value as Map)['role'] == 'admin') {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardWrapper()));
      } else { await FirebaseAuth.instance.signOut(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authorized'))); }
    } on FirebaseAuthException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed'))); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login'), backgroundColor: Colors.transparent),
      body: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple])), child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Card(elevation: 12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
            const Icon(Icons.admin_panel_settings, size: 60, color: Colors.blue),
            const Text('Admin Access', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: _emailController, decoration: _inputDecoration('Admin Email', Icons.email)),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration('Password', Icons.lock)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Login as Admin', style: TextStyle(fontSize: 18))),
          ])),
        ),
      ))),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
}

// ==================== ADMIN PROFILE SCREEN ====================
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
    if (snapshot.exists && mounted) setState(() => _userData = Map<String, dynamic>.from(snapshot.value as Map));
  }
  Future<void> _updatePassword() async {
    final newPassword = _newPasswordController.text.trim(); if (newPassword.isEmpty) return;
    try { await FirebaseAuth.instance.currentUser!.updatePassword(newPassword); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated'))); _newPasswordController.clear(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }
  @override
  Widget build(BuildContext context) {
    if (_userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const CircleAvatar(radius: 50, child: Icon(Icons.admin_panel_settings, size: 50)),
        const SizedBox(height: 20),
        Text('Name: ${_userData!['name']}', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        const Text('Role: Admin', style: TextStyle(fontSize: 16, color: Colors.blue)),
        const Divider(height: 40),
        TextField(controller: _newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _updatePassword, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Update Password')),
      ])),
    );
  }
}

// ==================== ROUTES SCREEN (User) ====================
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});
  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}
class _RoutesScreenState extends State<RoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadRoutes(); }
  Future<void> _loadRoutes() async {
    final snap = await getDatabase().ref('routes').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() { _routes = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList(); _isLoading = false; });
    } else { setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bus Routes')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _routes.length,
        itemBuilder: (ctx, i) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ExpansionTile(
            leading: const Icon(Icons.directions_bus, color: Colors.blue),
            title: Text(_routes[i]['name']),
            subtitle: Text('⏰ ${_routes[i]['timing']}'),
            children: [Padding(padding: const EdgeInsets.all(12), child: Text('🛑 Stops: ${_routes[i]['stops']}', style: const TextStyle(fontSize: 14)))],
          ),
        ),
      ),
    );
  }
}

// ==================== EMERGENCY SCREEN (User) ====================
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}
class _EmergencyScreenState extends State<EmergencyScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  @override
  void initState() { super.initState(); _loadContacts(); }
  Future<void> _loadContacts() async {
    final snap = await getDatabase().ref('emergencyContacts').get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      setState(() { _contacts = data.entries.map((e) => Map<String, dynamic>.from(e.value)).toList(); _isLoading = false; });
    } else { setState(() => _isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _contacts.length,
        itemBuilder: (ctx, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.contact_emergency, color: Colors.red),
            title: Text(_contacts[i]['name']),
            subtitle: Text(_contacts[i]['number']),
            trailing: IconButton(icon: const Icon(Icons.phone, color: Colors.blue), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling ${_contacts[i]['number']}...')))),
          ),
        ),
      ),
    );
  }
}

// ==================== APPLY TRANSPORT SCREEN ====================
class ApplyTransportScreen extends StatefulWidget {
  const ApplyTransportScreen({super.key});

  @override
  State<ApplyTransportScreen> createState() =>
      _ApplyTransportScreenState();
}

class _ApplyTransportScreenState
    extends State<ApplyTransportScreen> {
  final _phoneController = TextEditingController();

  final _emailController = TextEditingController();

  final _regIdController = TextEditingController();

  final _departmentController =
      TextEditingController();

  String _selectedRoute = '';

  List<String> _routesList = [];

  bool _hasApplied = false;

  bool _isLoading = true;

  Map<String, dynamic>? _existingApplication;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadUserData(),
      _loadRoutes(),
      _checkExistingApplication(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _regIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final snap =
          await getDatabase().ref('users/$uid').get();

      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(
          snap.value as Map,
        );

        _phoneController.text =
            data['phone']?.toString() ?? '';

        _emailController.text =
            data['email']?.toString() ?? '';

        _departmentController.text =
            data['department']?.toString() ?? '';

        if (data['userType'] == 'student') {
          _regIdController.text =
              data['registrationNumber']
                      ?.toString() ??
                  '';
        } else {
          _regIdController.text =
              data['universityId']
                      ?.toString() ??
                  '';
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final snap =
          await getDatabase().ref('routes').get();

      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(
          snap.value as Map,
        );

        final routes = data.entries.map((e) {
          final routeData =
              Map<dynamic, dynamic>.from(
            e.value,
          );

          return routeData['name']
                  ?.toString() ??
              '';
        }).toList();

        if (!mounted) return;

        setState(() {
          _routesList = routes;
        });
      }
    } catch (e) {
      debugPrint('Routes load error: $e');
    }
  }

  Future<void> _checkExistingApplication() async {
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final snap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(
          snap.value as Map,
        );

        if (data.isNotEmpty) {
          if (!mounted) return;

          setState(() {
            _hasApplied = true;

            _existingApplication =
                Map<String, dynamic>.from(
              data.values.first,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Application check error: $e');
    }
  }

  Future<void> _submitApplication() async {
    if (_selectedRoute.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select route'),
        ),
      );

      return;
    }

    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final userSnap =
          await getDatabase().ref('users/$uid').get();

      if (!userSnap.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User data not found'),
          ),
        );

        return;
      }

      final userData = Map<String, dynamic>.from(
        userSnap.value as Map,
      );

      await getDatabase()
          .ref('applications')
          .push()
          .set({
        'userId': uid,
        'name': userData['name'],
        'userType': userData['userType'],
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'department':
            _departmentController.text.trim(),
        'regId': _regIdController.text.trim(),
        'route': _selectedRoute,
        'status': 'pending',
        'submittedAt': ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application submitted!',
          ),
        ),
      );

      await _checkExistingApplication();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasApplied &&
        _existingApplication != null) {
      final status =
          _existingApplication?['status']
                  ?.toString() ??
              'pending';

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Transport Application',
          ),
        ),

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
                        : status == 'rejected'
                            ? Icons.cancel
                            : Icons.pending,

                    size: 64,

                    color: status == 'approved'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Status: $status',
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (status == 'approved' &&
                      _existingApplication?[
                              'challanUrl'] !=
                          null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ChallanViewScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        'View Challan',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Apply Transport',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            TextField(
              controller: _phoneController,

              decoration: _inputDecoration(
                'Phone Number',
                Icons.phone,
              ),

              enabled: false,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _emailController,

              decoration: _inputDecoration(
                'Email',
                Icons.email,
              ),

              enabled: false,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _regIdController,

              decoration: _inputDecoration(
                'Registration / University ID',
                Icons.badge,
              ),

              enabled: false,
            ),

            const SizedBox(height: 12),

            TextField(
              controller:
                  _departmentController,

              decoration: _inputDecoration(
                'Department',
                Icons.business,
              ),

              enabled: false,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue:
                  _selectedRoute.isEmpty
                      ? null
                      : _selectedRoute,

              hint: const Text(
                'Select Route',
              ),

              items: _routesList
                  .map<
                      DropdownMenuItem<
                          String>>(
                (String route) {
                  return DropdownMenuItem<
                      String>(
                    value: route,
                    child: Text(route),
                  );
                },
              ).toList(),

              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedRoute = value;
                  });
                }
              },

              decoration: _inputDecoration(
                'Route',
                Icons.route,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _submitApplication,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,

                minimumSize: const Size(
                  double.infinity,
                  50,
                ),
              ),

              child: const Text(
                'Submit Application',
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
    );
  }
}

// ==================== CHALLAN VIEW SCREEN ====================
class ChallanViewScreen extends StatefulWidget {
  const ChallanViewScreen({super.key});
  @override
  State<ChallanViewScreen> createState() => _ChallanViewScreenState();
}
class _ChallanViewScreenState extends State<ChallanViewScreen> {
  Map<String, dynamic>? _challanData; bool _isUploading = false;
  @override
  void initState() { super.initState(); _fetchChallan(); }
  Future<void> _fetchChallan() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists && mounted) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        final app = data.values.first;
        if (app['challanUrl'] != null) setState(() { _challanData = { 'url': app['challanUrl'], 'status': app['paymentStatus'] ?? 'pending' }; });
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
        await ref.putFile(File(picked.path)); final proofUrl = await ref.getDownloadURL();
        await getDatabase().ref('applications/$appKey').update({ 'paidProofUrl': proofUrl, 'paymentStatus': 'proof_uploaded' });
      }
    }
    if (mounted) { setState(() => _isUploading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proof uploaded, waiting for admin verification.'))); showReminder('Payment Proof Submitted', 'Your payment proof is under review.'); }
  }
  @override
  Widget build(BuildContext context) {
    if (_challanData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Challan')),
      body: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Text('Admin Issued Challan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
          Text('Challan URL: ${_challanData!['url']}'),
          const SizedBox(height: 16),
          if (_challanData!['status'] == 'pending') ElevatedButton.icon(onPressed: _uploadPaidProof, icon: const Icon(Icons.upload), label: const Text('Upload Paid Proof')),
          if (_isUploading) const CircularProgressIndicator(),
          if (_challanData!['status'] == 'proof_uploaded') const Text('Proof uploaded, admin will verify soon.'),
          if (_challanData!['status'] == 'paid') const Text('Payment verified! You can now generate card.'),
        ]),
      ))),
    );
  }
}

// ==================== TRANSPORT CARD SCREEN ====================
class TransportCardScreen extends StatefulWidget {
  const TransportCardScreen({super.key});
  @override
  State<TransportCardScreen> createState() => _TransportCardScreenState();
}
class _TransportCardScreenState extends State<TransportCardScreen> {
  final _emailController = TextEditingController(); final _passwordController = TextEditingController();
  bool _isLoading = false; Map<String, dynamic>? _cardData;
  Future<void> _generateCard() async {
    final user = FirebaseAuth.instance.currentUser!;
    if (_emailController.text.trim() != user.email) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email mismatch'))); return; }
    if (_passwordController.text.trim() != user.email) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password'))); return; }
    setState(() => _isLoading = true);
    final uid = user.uid;
    final appSnap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (!appSnap.exists) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No application'))); setState(() => _isLoading = false); return; }
    final apps = appSnap.value as Map<dynamic, dynamic>;
    if (apps.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No application'))); setState(() => _isLoading = false); return; }
    final app = apps.values.first;
    if (app['paymentStatus'] != 'paid') { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment not verified yet.'))); setState(() => _isLoading = false); return; }
    final cardSnap = await getDatabase().ref('transportCards').orderByChild('userId').equalTo(uid).get();
    if (cardSnap.exists && cardSnap.value != null) {
      final cards = cardSnap.value as Map<dynamic, dynamic>;
      if (cards.isNotEmpty) { setState(() { _cardData = Map<String, dynamic>.from(cards.values.first); _isLoading = false; }); return; }
    }
    final cardNumber = 'CM-${DateTime.now().millisecondsSinceEpoch}';
    final newCardRef = getDatabase().ref('transportCards').push();
    await newCardRef.set({ 'userId': uid, 'cardNumber': cardNumber, 'issueDate': ServerValue.timestamp, 'expiry': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch, 'valid': true });
    final snap = await newCardRef.get();
    setState(() { _cardData = Map<String, dynamic>.from(snap.value as Map); _isLoading = false; });
  }
  @override
  Widget build(BuildContext context) {
    if (_cardData != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Transport Card')),
        body: Center(child: Card(elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), margin: const EdgeInsets.all(24),
          child: Container(width: 320, padding: const EdgeInsets.all(24), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.blue, Colors.purple]), borderRadius: BorderRadius.all(Radius.circular(32))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.credit_card, size: 60, color: Colors.white),
              const Text('Campus Move', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Card #: ${_cardData!['cardNumber']}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Text('Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_cardData!['expiry']))}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              const Icon(Icons.qr_code_scanner, size: 80, color: Colors.white),
            ]),
          ),
        )),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Transport Card')),
      body: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Your Email', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password (use email as password)', border: OutlineInputBorder())),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _generateCard, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: _isLoading ? const CircularProgressIndicator() : const Text('Generate Card')),
      ])),
    );
  }
}

// ==================== PROFILE SCREEN ====================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? _application;

  Map<String, dynamic>? _transportCard;

  bool _isLoading = true;

  String? _profilePicUrl;

  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _guardianNameCtrl =
      TextEditingController();

  final TextEditingController _guardianPhoneCtrl =
      TextEditingController();

  final TextEditingController _newPasswordCtrl =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _guardianNameCtrl.dispose();
    _guardianPhoneCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    await _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });

        return;
      }

      final uid = user.uid;

      final userSnap =
          await getDatabase()
              .ref('users/$uid')
              .get();

      if (!userSnap.exists) {
        if (!mounted) return;

        setState(() {
          _errorMessage =
              'User data not found';

          _isLoading = false;
        });

        return;
      }

      final userData =
          Map<String, dynamic>.from(
        userSnap.value as Map,
      );

      _guardianNameCtrl.text =
          userData['guardianName']
                  ?.toString() ??
              '';

      _guardianPhoneCtrl.text =
          userData['guardianPhone']
                  ?.toString() ??
              '';

      final appSnap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? appData;

      if (appSnap.exists &&
          appSnap.value != null) {
        final apps =
            Map<dynamic, dynamic>.from(
          appSnap.value as Map,
        );

        if (apps.isNotEmpty) {
          appData =
              Map<String, dynamic>.from(
            apps.values.first,
          );
        }
      }

      final cardSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(uid)
          .get();

      Map<String, dynamic>? cardData;

      if (cardSnap.exists &&
          cardSnap.value != null) {
        final cards =
            Map<dynamic, dynamic>.from(
          cardSnap.value as Map,
        );

        if (cards.isNotEmpty) {
          cardData =
              Map<String, dynamic>.from(
            cards.values.first,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _userData = userData;

        _profilePicUrl =
            userData['profilePic']
                ?.toString();

        _application = appData;

        _transportCard = cardData;

        _isLoading = false;

        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error: $e';

        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePic() async {
    try {
      final picked =
          await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked != null) {
        final uid =
            FirebaseAuth.instance.currentUser!.uid;

        final ref = FirebaseStorage.instance
            .ref()
            .child(
              'profilePics/$uid.jpg',
            );

        await ref.putFile(
          File(picked.path),
        );

        final url =
            await ref.getDownloadURL();

        await getDatabase()
            .ref('users/$uid')
            .update({
          'profilePic': url,
        });

        if (!mounted) return;

        setState(() {
          _profilePicUrl = url;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  Future<void> _updateGuardian() async {
    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      await getDatabase()
          .ref('users/$uid')
          .update({
        'guardianName':
            _guardianNameCtrl.text.trim(),

        'guardianPhone':
            _guardianPhoneCtrl.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Guardian info updated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPass =
        _newPasswordCtrl.text.trim();

    if (newPass.isEmpty) {
      return;
    }

    try {
      await FirebaseAuth.instance
          .currentUser!
          .updatePassword(newPass);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully',
          ),
        ),
      );

      _newPasswordCtrl.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  Future<void> _downloadChallan(
    String url,
  ) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          .showSnackBar(
          const SnackBar(
            content: Text(
              'Cannot open file',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Profile',
          ),
        ),

        body: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              Text(_errorMessage!),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _refreshData,

                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
        ),

        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh),

            onPressed: _refreshData,
          ),
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

                  backgroundImage:
                      _profilePicUrl != null
                          ? NetworkImage(
                              _profilePicUrl!,
                            )
                          : null,

                  child:
                      _profilePicUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                            )
                          : null,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,

                  child: CircleAvatar(
                    backgroundColor:
                        Colors.blue,

                    radius: 18,

                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),

                      onPressed:
                          _updateProfilePic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            leading:
                const Icon(Icons.person),

            title: const Text('Name'),

            subtitle: Text(
              _userData?['name']
                      ?.toString() ??
                  '',
            ),
          ),

          ListTile(
            leading:
                const Icon(Icons.email),

            title: const Text('Email'),

            subtitle: Text(
              _userData?['email']
                      ?.toString() ??
                  '',
            ),
          ),

          ListTile(
            leading:
                const Icon(Icons.phone),

            title: const Text('Phone'),

            subtitle: Text(
              _userData?['phone']
                      ?.toString() ??
                  '',
            ),
          ),

          ListTile(
            leading:
                const Icon(Icons.business),

            title:
                const Text('Department'),

            subtitle: Text(
              _userData?['department']
                      ?.toString() ??
                  '',
            ),
          ),

          const Divider(),

          const Text(
            'Guardian Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextField(
            controller: _guardianNameCtrl,

            decoration:
                const InputDecoration(
              labelText:
                  'Guardian Name',

              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
                _guardianPhoneCtrl,

            keyboardType:
                TextInputType.phone,

            decoration:
                const InputDecoration(
              labelText:
                  'Guardian Phone',

              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: _updateGuardian,

            child: const Text(
              'Save Guardian Info',
            ),
          ),

          const Divider(),

          const Text(
            'Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          TextField(
            controller: _newPasswordCtrl,

            obscureText: true,

            decoration:
                const InputDecoration(
              labelText:
                  'New Password',

              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: _changePassword,

            child: const Text(
              'Change Password',
            ),
          ),

          const Divider(),

          const Text(
            'Application Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_application != null) ...[
            ListTile(
              title: Text(
                'Route: ${_application?['route'] ?? ''}',
              ),

              subtitle: Text(
                'Status: ${_application?['status'] ?? ''} | Payment: ${_application?['paymentStatus'] ?? 'Pending'}',
              ),
            ),

            if (_application?['status'] ==
                    'approved' &&
                _application?[
                        'challanUrl'] !=
                    null)
              ElevatedButton.icon(
                onPressed: () {
                  _downloadChallan(
                    _application![
                        'challanUrl'],
                  );
                },

                icon:
                    const Icon(Icons.download),

                label: const Text(
                  'Download Challan',
                ),
              ),

            if (_application?[
                    'paymentStatus'] ==
                'pending')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChallanViewScreen(),
                    ),
                  );
                },

                child: const Text(
                  'Upload Payment Proof',
                ),
              ),
          ] else
            const Text(
              'No application submitted yet.',
            ),

          const Divider(),

          const Text(
            'Transport Card',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_transportCard != null)
            Card(
              color: Colors.blue.shade100,

              child: ListTile(
                title: Text(
                  'Card #: ${_transportCard?['cardNumber'] ?? ''}',
                ),

                subtitle: Text(
                  'Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_transportCard?['expiry'] ?? 0))}',
                ),
              ),
            )
          else
            const Text(
              'Card not generated yet.',
            ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),

            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
              ),
            ),

            onTap: _logout,
          ),
        ],
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
  bool _sending = false; String _userName = '';
  @override
  void initState() { super.initState(); _loadUserName(); }
  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await getDatabase().ref('users/${user.uid}').get();
      if (snap.exists && mounted) setState(() { _userName = (snap.value as Map)['name'] ?? 'Student'; });
    }
  }
  Future<void> _sendSOS() async {
    if (_sending) return; setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first'))); setState(() => _sending = false); return; }
    try {
      await getDatabase().ref('sosAlerts').push().set({ 'userId': user.uid, 'userName': _userName, 'timestamp': ServerValue.timestamp, 'status': 'active' });
      const String topic = 'campus_move_emergency_123';
      final url = Uri.parse('https://ntfy.sh/$topic');
      final response = await http.post(url, body: 'EMERGENCY SOS - Campus Move\n\nStudent Name: $_userName\nTime: ${DateTime.now()}\nPlease call immediately.');
      if (response.statusCode == 200) { showReminder('SOS Sent', 'Emergency alert sent to guardian & admin.'); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS sent! Guardian notified.'))); }
      else { throw Exception('Ntfy error: ${response.statusCode}'); }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    finally { if (mounted) setState(() => _sending = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.warning, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          const Text('Tap button to send emergency alert', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text('Notifying: campus_move_emergency_123', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(onPressed: _sending ? null : _sendSOS, icon: const Icon(Icons.sos, size: 30), label: const Text('SEND SOS', style: TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
          if (_sending) const Padding(padding: EdgeInsets.only(top: 16), child: CircularProgressIndicator()),
        ]),
      ),
    );
  }
}

// ==================== STUDENT ATTENDANCE SCREEN ====================
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}
class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool _isScanning = false; String _result = '';
  final MobileScannerController scannerController = MobileScannerController();
  Future<bool> _checkPaymentStatus() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await getDatabase().ref('applications').orderByChild('userId').equalTo(uid).get();
    if (snap.exists && snap.value != null) { final data = snap.value as Map<dynamic, dynamic>; if (data.isNotEmpty) { final app = data.values.first; if (app['paymentStatus'] == 'paid') return true; } }
    return false;
  }
  @override void dispose() { scannerController.dispose(); super.dispose(); }
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanning) return;
    final isPaid = await _checkPaymentStatus();
    if (!isPaid) { if (mounted) { setState(() => _result = '⚠️ Please complete fee payment first to mark attendance.'); Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _result = ''); }); } return; }
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code.startsWith('CAMPUS_MOVE_ATTENDANCE|')) {
      if (mounted) setState(() { _isScanning = true; _result = 'Processing...'; });
      final parts = code.split('|');
      if (parts.length >= 4) {
        final sessionId = parts[1]; final route = parts[2];
        final sessionSnap = await getDatabase().ref('attendanceSessions/$sessionId').get();
        if (!sessionSnap.exists) { _result = 'Invalid or expired QR code.'; }
        else {
          final expiryMap = sessionSnap.value as Map<dynamic, dynamic>;
          if (DateTime.now().millisecondsSinceEpoch > (expiryMap['expiry'] as int)) { _result = 'QR code expired.'; }
          else {
            final user = FirebaseAuth.instance.currentUser!;
            final userSnap = await getDatabase().ref('users/${user.uid}').get();
            final studentName = (userSnap.value as Map<dynamic, dynamic>)['name'] as String;
            await getDatabase().ref('attendance').push().set({ 'studentId': user.uid, 'studentName': studentName, 'route': route, 'timestamp': ServerValue.timestamp, 'date': DateTime.now().toIso8601String() });
            _result = 'Attendance marked for route $route!';
            showReminder('Attendance Marked', 'You have marked attendance for $route');
          }
        }
      } else { _result = 'Invalid QR code.'; }
      if (mounted) { setState(() { _isScanning = false; }); Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _result = ''); }); }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Column(children: [
        Expanded(flex: 3, child: MobileScanner(controller: scannerController, onDetect: _onDetect)),
        Expanded(child: Center(child: Text(_result, style: const TextStyle(fontSize: 16)))),
      ]),
    );
  }
}

// ==================== FEEDBACK SCREEN ====================
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}
class _FeedbackScreenState extends State<FeedbackScreen> {
  final _nameController = TextEditingController(); final _emailController = TextEditingController(); final _commentController = TextEditingController(); bool _isSending = false;
  Future<void> _sendFeedback() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _commentController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields'))); return; }
    setState(() => _isSending = true);
    await getDatabase().ref('feedbacks').push().set({ 'name': _nameController.text.trim(), 'email': _emailController.text.trim(), 'comment': _commentController.text.trim(), 'timestamp': ServerValue.timestamp });
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you!'))); Navigator.pop(context); }
    setState(() => _isSending = false);
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Send Feedback')), body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Your Email', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    TextField(controller: _commentController, maxLines: 5, decoration: const InputDecoration(labelText: 'Comment', border: OutlineInputBorder())),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _isSending ? null : _sendFeedback, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: _isSending ? const CircularProgressIndicator() : const Text('Send Feedback'))
  ])));
}

// ==================== DEVELOPER INFO SCREEN ====================
class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final developers = [
      {'name': 'Hafsa Saleem', 'role': 'Lecturer at CUI', 'image': 'assets/dev1.png', 'email': 'hafsasaleem@gmail.com', 'phone': 'Nil'},
      {'name': 'Nouman Nadir', 'role': ' Developer', 'image': 'assets/dev2.jpeg', 'email': 'noumannadir595@gmail.com', 'phone': '+92 325 9869056'},
      {'name': 'Aqsa', 'role': ' Developer', 'image': 'assets/dev3.jpeg', 'email': 'aqsaqamar0499@gmail.com', 'phone': 'Nil'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Info')),
      body: ListView.builder(padding: const EdgeInsets.all(16), itemCount: developers.length,
        itemBuilder: (ctx, i) {
          final dev = developers[i];
          return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              CircleAvatar(radius: 40, backgroundImage: AssetImage(dev['image']!), onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 40)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dev['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(dev['role']!, style: const TextStyle(color: Colors.blue)),
                const SizedBox(height: 4), Text('Email: ${dev['email']}', style: const TextStyle(fontSize: 12)), Text('Phone: ${dev['phone']}', style: const TextStyle(fontSize: 12))
              ])),
            ])),
          );
        },
      ),
    );
  }
}

// ==================== LOGIN SCREEN ====================
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
        email: _emailController.text.trim(), password: _passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'User not found';
      } else if (e.code == 'wrong-password') msg = 'Wrong password';
      else if (e.code == 'invalid-email') msg = 'Invalid email';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good Morning!';
    if (hour < 16) return '🌸 Good Afternoon!';
    if (hour < 20) return '🌙 Good Evening!';
    return '🌃 Good Night!';
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
            child: Card(elevation: 12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
                const Icon(Icons.directions_bus, size: 60, color: Colors.blue),
                const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_getGreeting(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 30),
                TextField(controller: _emailController, decoration: _inputDecoration('Email', Icons.email)),
                const SizedBox(height: 16),
                TextField(controller: _passwordController, obscureText: true, decoration: _inputDecoration('Password', Icons.lock)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Login', style: TextStyle(fontSize: 18))),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())), child: const Text("Don't have an account? Sign Up")),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverSignupScreen())), child: const Text('Register as Driver')),
              ])),
            ),
          ),
        ),
      ),
    );
  }
  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)));
}

// ==================== SIGNUP SCREEN ====================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _regIdCtrl = TextEditingController();

  String _userType = 'student';
  bool _isLoading = false;

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }

    if (value.length < 10) {
      return 'Invalid phone';
    }

    return null;
  }

  Future<void> _signup() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _deptCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    if (_userType == 'student' && _regIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration number required')),
      );
      return;
    }

    if (_userType == 'faculty' && _regIdCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('University ID required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final role =
          _emailCtrl.text.trim() == 'admin@campusmove.com'
              ? 'admin'
              : 'user';

      final Map<String, dynamic> userData = {
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'userType': _userType,
        'role': role,
        'department': _deptCtrl.text.trim(),
        'createdAt': ServerValue.timestamp,
      };

      if (_userType == 'student') {
        userData['registrationNumber'] =
            _regIdCtrl.text.trim();
      } else {
        userData['universityId'] =
            _regIdCtrl.text.trim();
      }

      await getDatabase()
          .ref('users/${cred.user!.uid}')
          .set(userData);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.purple,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration(
                        'Full Name',
                        Icons.person,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _emailCtrl,
                      decoration: _inputDecoration(
                        'Email',
                        Icons.email,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: _inputDecoration(
                        'Password',
                        Icons.lock,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: _inputDecoration(
                        'Phone Number',
                        Icons.phone,
                      ),
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _deptCtrl,
                      decoration: _inputDecoration(
                        'Department',
                        Icons.business,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _userType,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'faculty',
                          child: Text('Faculty'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _userType = val);
                        }
                      },
                      decoration: _inputDecoration(
                        'I am a',
                        Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _regIdCtrl,
                      decoration: _inputDecoration(
                        _userType == 'student'
                            ? 'Registration Number'
                            : 'University ID',
                        Icons.badge,
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize:
                            const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Already have an account? Login',
                      ),
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

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ==================== END ====================
