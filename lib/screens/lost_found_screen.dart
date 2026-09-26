import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/database.dart';
import '../core/providers.dart';

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
    final snap =
        await getDatabase().ref('lostfound').orderByChild('timestamp').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _items = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
        _items.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _isUploading = true);
        final ref = FirebaseStorage.instance.ref().child(
            'lostfound/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(picked.path));
        final url = await ref.getDownloadURL();
        setState(() {
          _imageUrl = url;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully!')));
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _postItem() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty ||
        _contactCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    setState(() => _isUploading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to post')));
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
      _titleCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
      _contactCtrl.clear();
      setState(() {
        _imageUrl = null;
        _isUploading = false;
      });
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Posted successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error posting: $e')));
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
                          if (item['imageUrl'] != null &&
                              item['imageUrl'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                      child:
                                          Image.network(item['imageUrl']))),
                              child: Image.network(item['imageUrl'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
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
                                      child: Text(item['type'],
                                          style: TextStyle(
                                              color: item['type'] == 'Lost'
                                                  ? Colors.red
                                                  : Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(item['title'],
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold))),
                                    if (isAdmin || item['userId'] == user?.uid)
                                      IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20),
                                          onPressed: () =>
                                              _deleteItem(item['id'])),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('📍 ${item['location']}'),
                                Text('📝 ${item['description']}'),
                                const SizedBox(height: 8),
                                Text('📞 ${item['contact']}',
                                    style:
                                        const TextStyle(color: Colors.blue)),
                                Text('👤 ${item['userName']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                    '📅 ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(item['timestamp']))}'),
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
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Post Lost/Found',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description')),
              TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location')),
              TextField(
                  controller: _contactCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Contact Number')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(
                          _imageUrl != null ? 'Image Added' : 'Add Image'),
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
        ),
      ),
    );
  }
}