import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddLostFoundSheet(
        onPostAdded: _loadPosts,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Post'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('Lost'),
                _buildTabContent('Found'),
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
                'Tap "Add Post" to create one',
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

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isLost = post['type'] == 'Lost';
    final badgeColor = isLost ? AppColors.lostBadge : AppColors.foundBadge;
    final user = FirebaseAuth.instance.currentUser;
    final canDelete = post['userId'] == user?.uid;
    final hasImage =
        post['imageUrl'] != null && post['imageUrl'].toString().isNotEmpty;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                post['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Lost/Found Badge
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
        maxWidth: 1200,
      );

      if (picked != null) {
        setState(() => _pickedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _submit() async {
    // Validate
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
      // Get user name
      String userName = 'User';
      try {
        final userSnap = await getDatabase().ref('users/${user.uid}').get();
        if (userSnap.exists) {
          userName = (userSnap.value as Map)['name']?.toString() ?? 'User';
        }
      } catch (_) {}

      // Upload image
      String imageUrl = '';
      try {
        final fileName =
            'lostfound_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('lostfound/$fileName');

        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(_pickedImage!.path));
        }

        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (mounted) {
          CustomSnackbar.error(context, 'Image upload failed: $e');
        }
        setState(() => _isSubmitting = false);
        return;
      }

      // Save to Firebase
      await getDatabase().ref('lostfound').push().set({
        'type': _selectedType,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'imageUrl': imageUrl,
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
              // Handle
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
              // Title
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
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Type selector
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

                    // Title
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g., Black wallet',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
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

                    // Location
                    TextField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Where did you lose/find it?',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contact
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

                    // Image picker
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
                            style: BorderStyle.solid,
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
                                        fit: BoxFit.cover,
                                      )
                                    else
                                      Image.file(
                                        File(_pickedImage!.path),
                                        fit: BoxFit.cover,
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

                    // Submit
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