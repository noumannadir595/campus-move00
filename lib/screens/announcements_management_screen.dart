import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../core/database.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});
  @override
  State<AnnouncementsManagementScreen> createState() =>
      _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState
    extends State<AnnouncementsManagementScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final snap = await getDatabase().ref('announcements').get();
    if (snap.exists) {
      final Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
      setState(() {
        _announcements = data.entries
            .map((e) => {'id': e.key, ...Map<String, dynamic>.from(e.value)})
            .toList();
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
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _msgCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Message', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _post,
                child: const Text('Post Announcement')),
          ]),
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
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => _delete(a['id'])),
                        ),
                      );
                    },
                  )),
      ]),
    );
  }
}