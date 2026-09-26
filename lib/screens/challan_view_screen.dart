import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/database.dart';
import '../core/notifications.dart';

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
    final snap = await getDatabase()
        .ref('applications')
        .orderByChild('userId')
        .equalTo(uid)
        .get();
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
    final snap = await getDatabase()
        .ref('applications')
        .orderByChild('userId')
        .equalTo(uid)
        .get();
    if (snap.exists) {
      final data = snap.value as Map<dynamic, dynamic>;
      if (data.isNotEmpty) {
        final appKey = data.keys.first;
        final ref = FirebaseStorage.instance.ref().child(
            'proofs/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(picked.path));
        final proofUrl = await ref.getDownloadURL();
        await getDatabase().ref('applications/$appKey').update({
          'paidProofUrl': proofUrl,
          'paymentStatus': 'proof_uploaded'
        });
      }
    }
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Proof uploaded, waiting for admin verification.')));
      showReminder('Payment Proof Submitted',
          'Your payment proof is under review.');
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
          child: Column(children: [
            const Text('Admin Issued Challan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
            Text('Challan URL: ${_challanData!['url']}'),
            const SizedBox(height: 16),
            if (_challanData!['status'] == 'pending')
              ElevatedButton.icon(
                  onPressed: _uploadPaidProof,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Paid Proof')),
            if (_isUploading) const CircularProgressIndicator(),
            if (_challanData!['status'] == 'proof_uploaded')
              const Text('Proof uploaded, admin will verify soon.'),
            if (_challanData!['status'] == 'paid')
              const Text('Payment verified! You can now generate card.'),
          ]),
        )),
      ),
    );
  }
}