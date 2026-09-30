import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allPosts = [];
  bool _loading = true;
  bool _hasAccess = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkTransportAccessAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==================== CHECK TRANSPORT ACCESS ====================
  Future<bool> _checkTransportAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // 1. User profile check
      final userSnap = await getDatabase().ref('users/${user.uid}').get();
      if (!userSnap.exists) return false;
      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      if ((userData['name'] ?? '').toString().trim().isEmpty) return false;

      // 2. Application approved check
      final appSnap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(user.uid)
          .get();
      if (!appSnap.exists) return false;

      final apps = Map<dynamic, dynamic>.from(appSnap.value as Map);
      if (apps.isEmpty) return false;

      final app = Map<String, dynamic>.from(apps.values.first);
      if (app['status'] != 'approved') return false;

      // 3. Transport card uploaded check
      final cardSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(user.uid)
          .get();
      if (!cardSnap.exists) return false;

      final cards = Map<dynamic, dynamic>.from(cardSnap.value as Map);
      if (cards.isEmpty) return false;

      final card = Map<String, dynamic>.from(cards.values.first);

      final hasImage = card['cardImageBase64'] != null &&
          card['cardImageBase64'].toString().isNotEmpty;
      if (!hasImage) return false;

      if (card['valid'] == false) return false;

      final expiry = card['expiry'];
      if (expiry != null) {
        final expMs = int.tryParse(expiry.toString()) ?? 0;
        if (expMs > 0 &&
            DateTime.now().millisecondsSinceEpoch > expMs) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Access check error: $e');
      return false;
    }
  }

  Future<void> _checkTransportAccessAndLoad() async {
    setState(() => _checkingAccess = true);
    final hasAccess = await _checkTransportAccess();
    if (!mounted) return;
    setState(() {
      _hasAccess = hasAccess;
      _checkingAccess = false;
    });
    await _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final snap = await getDatabase()
          .ref('lostfound')
          .orderByChild('timestamp')
          .get();

      if (snap.exists) {
        final data = snap.value as Map<dynamic, dynamic>;
        final list = data.entries
            .map((e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value),
                })
            .toList();
        list.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        setState(() {
          _allPosts = list;
          _loading = false;
        });
      } else {
        setState(() {
          _allPosts = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _getFiltered(String type) {
    return _allPosts.where((p) => p['type'] == type).toList();
  }

  Future<void> _deletePost(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await getDatabase().ref('lostfound/$id').remove();
      CustomSnackbar.success(context, 'Post deleted');
      _loadPosts();
    }
  }

  void _openAddSheet() async {
    final hasAccess = await _checkTransportAccess();
    if (!mounted) return;

    if (!hasAccess) {
      _showAccessDeniedDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddLostFoundSheet(
        onPostAdded: _loadPosts,
      ),
    );
  }

  void _showAccessDeniedDialog() {
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
            Text('Access Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To post in Lost & Found, you need transport access.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text('• Complete profile',
                style: TextStyle(fontSize: 13, height: 1.6)),
            Text('• Transport application approved',
                style: TextStyle(fontSize: 13, height: 1.6)),
            Text('• Transport card uploaded by admin',
                style: TextStyle(fontSize: 13, height: 1.6)),
            SizedBox(height: 12),
            Text(
              'Please apply for transport first and wait for admin approval.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.search_off_rounded, size: 20),
              text: 'Lost Items',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline_rounded, size: 20),
              text: 'Found Items',
            ),
          ],
        ),
      ),
      floatingActionButton: _hasAccess
          ? FloatingActionButton.extended(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Post'),
            )
          : null,
      body: _checkingAccess
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_hasAccess) _buildNoAccessBanner(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTabContent('Lost'),
                            _buildTabContent('Found'),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  // ==================== VIEW ONLY MODE BANNER (ENGLISH) ====================
  Widget _buildNoAccessBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.15),
            Colors.red.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline,
                color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View Only Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'You need transport access to post. Apply for transport first.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String type) {
    final posts = _getFiltered(type);

    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'Lost'
                      ? Icons.search_off_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                type == 'Lost'
                    ? 'No lost items posted'
                    : 'No found items posted',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasAccess
                    ? 'Tap "Add Post" to create one'
                    : 'Transport access required to post',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: posts.length,
        itemBuilder: (ctx, i) => _buildPostCard(posts[i]),
      ),
    );
  }

  // ==================== POST CARD (SQUARE IMAGE - NO CROP) ====================
  Widget _buildPostCard(Map<String, dynamic> post) {
    final isLost = post['type'] == 'Lost';
    final badgeColor = isLost ? AppColors.lostBadge : AppColors.foundBadge;
    final user = FirebaseAuth.instance.currentUser;
    final canDelete = post['userId'] == user?.uid;

    final hasImage = post['imageBase64'] != null &&
        post['imageBase64'].toString().isNotEmpty;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== SQUARE IMAGE (FULL - NO CROP) ====================
          if (hasImage)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1, // Square (1:1)
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.memory(
                          base64Decode(post['imageBase64']),
                          fit: BoxFit.contain, // Full image, no crop
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLost
                                ? Icons.search_off_rounded
                                : Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post['type'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (canDelete)
                      IconButton(
                        onPressed: () => _deletePost(post['id']),
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        tooltip: 'Delete',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _infoRow(Icons.description_outlined,
                    post['description'] ?? ''),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, post['location'] ?? ''),
                const SizedBox(height: 6),
                _infoRow(Icons.phone_outlined, post['contact'] ?? '',
                    isContact: true),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      post['userName'] ?? 'User',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(post['timestamp'] ?? 0),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isContact = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isContact ? AppColors.primary : Colors.black87,
              fontWeight: isContact ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff < 60000) return 'Just now';
    if (diff < 3600000) return '${(diff / 60000).toInt()}m ago';
    if (diff < 86400000) return '${(diff / 3600000).toInt()}h ago';
    return DateFormat.yMMMd().format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}

// ==================== ADD POST BOTTOM SHEET ====================
class AddLostFoundSheet extends StatefulWidget {
  final VoidCallback onPostAdded;

  const AddLostFoundSheet({super.key, required this.onPostAdded});

  @override
  State<AddLostFoundSheet> createState() => _AddLostFoundSheetState();
}

class _AddLostFoundSheetState extends State<AddLostFoundSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String _selectedType = 'Lost';
  XFile? _pickedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (picked == null) return;

      final sizeInBytes = await picked.length();
      if (sizeInBytes > 700 * 1024) {
        if (mounted) {
          CustomSnackbar.warning(
            context,
            'Image too large (${(sizeInBytes / 1024).toInt()} KB). Please choose a smaller image.',
          );
        }
        return;
      }

      setState(() => _pickedImage = picked);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      CustomSnackbar.warning(context, 'Please enter a title');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      CustomSnackbar.warning(context, 'Please enter a description');
      return;
    }
    if (_locationCtrl.text.trim().isEmpty) {
      CustomSnackbar.warning(context, 'Please enter a location');
      return;
    }
    if (_contactCtrl.text.trim().isEmpty) {
      CustomSnackbar.warning(context, 'Contact number is mandatory');
      return;
    }
    if (_contactCtrl.text.trim().length < 10) {
      CustomSnackbar.warning(context, 'Please enter a valid contact number');
      return;
    }
    if (_pickedImage == null) {
      CustomSnackbar.warning(context, 'Please add an image');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackbar.error(context, 'Please login to post');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Double-check access
      final appSnap = await getDatabase()
          .ref('applications')
          .orderByChild('userId')
          .equalTo(user.uid)
          .get();

      if (!appSnap.exists) {
        if (mounted) {
          CustomSnackbar.error(context, 'Transport access required');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final apps = Map<dynamic, dynamic>.from(appSnap.value as Map);
      if (apps.isEmpty) {
        if (mounted) {
          CustomSnackbar.error(context, 'Transport access required');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final app = Map<String, dynamic>.from(apps.values.first);
      if (app['status'] != 'approved') {
        if (mounted) {
          CustomSnackbar.error(
              context, 'Transport application not approved yet');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final cardSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(user.uid)
          .get();

      if (!cardSnap.exists) {
        if (mounted) {
          CustomSnackbar.error(
              context, 'Transport card not uploaded yet');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Get user name
      String userName = 'User';
      try {
        final userSnap = await getDatabase().ref('users/${user.uid}').get();
        if (userSnap.exists) {
          userName = (userSnap.value as Map)['name']?.toString() ?? 'User';
        }
      } catch (_) {}

      // Base64 encode
      String imageBase64 = '';
      try {
        final bytes = await _pickedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        if (mounted) {
          CustomSnackbar.error(context, 'Image encode failed: $e');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      await getDatabase().ref('lostfound').push().set({
        'type': _selectedType,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'imageBase64': imageBase64,
        'userId': user.uid,
        'userName': userName,
        'timestamp': ServerValue.timestamp,
      });

      if (!mounted) return;
      CustomSnackbar.success(context, 'Posted successfully!');
      widget.onPostAdded();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Create New Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text(
                      'Post Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            'Lost',
                            Icons.search_off_rounded,
                            AppColors.lostBadge,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _typeButton(
                            'Found',
                            Icons.check_circle_outline_rounded,
                            AppColors.foundBadge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g., Black wallet',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe the item',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Where did you lose/find it?',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _contactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number * (Mandatory)',
                        hintText: 'e.g., 03001234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Image * (Required)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: _pickedImage != null ? 200 : 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _pickedImage != null
                                ? AppColors.success
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _pickedImage == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 44, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (kIsWeb)
                                      Image.network(
                                        _pickedImage!.path,
                                        fit: BoxFit.contain,
                                      )
                                    else
                                      Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.contain,
                                      ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _pickedImage = null),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? 'Posting...' : 'POST',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _typeButton(String type, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}