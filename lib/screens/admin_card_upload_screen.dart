import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/database.dart';
import '../theme.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_button.dart';

class AdminCardUploadScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String routeName;
  final String regId;

  const AdminCardUploadScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.routeName,
    required this.regId,
  });

  @override
  State<AdminCardUploadScreen> createState() => _AdminCardUploadScreenState();
}

class _AdminCardUploadScreenState extends State<AdminCardUploadScreen> {
  XFile? _pickedImage;
  bool _isUploading = false;
  Map<String, dynamic>? _existingCard;
  bool _isLoading = true;

  final _cardNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingCard();
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCard() async {
    try {
      final snap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(widget.userId)
          .get();

      if (snap.exists) {
        final data = Map<dynamic, dynamic>.from(snap.value as Map);
        if (data.isNotEmpty) {
          final card = Map<String, dynamic>.from(data.values.first);
          if (mounted) {
            setState(() {
              _existingCard = card;
              _cardNumberCtrl.text = card['cardNumber']?.toString() ?? '';
            });
          }
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 800,
      );

      if (picked != null) {
        final bytes = await picked.length();
        if (bytes > 500 * 1024) {
          if (mounted) {
            CustomSnackbar.warning(
                context, 'Image too large! Choose a smaller image.');
          }
          return;
        }
        if (mounted) setState(() => _pickedImage = picked);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Failed: $e');
      }
    }
  }

  Future<void> _save() async {
    if (_pickedImage == null && _existingCard == null) {
      CustomSnackbar.warning(context, 'Please select a card image');
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? cardImageBase64 = _existingCard?['cardImageBase64'];

      // Convert picked image to base64
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        cardImageBase64 = base64Encode(bytes);
      }

      final cardNumber = _cardNumberCtrl.text.trim().isEmpty
          ? 'CM-${DateTime.now().millisecondsSinceEpoch}'
          : _cardNumberCtrl.text.trim();

      final adminUid = FirebaseAuth.instance.currentUser!.uid;

      // Check if card already exists
      final existingSnap = await getDatabase()
          .ref('transportCards')
          .orderByChild('userId')
          .equalTo(widget.userId)
          .get();

      if (existingSnap.exists) {
        final data = Map<dynamic, dynamic>.from(existingSnap.value as Map);
        if (data.isNotEmpty) {
          final cardId = data.keys.first;
          // Update existing
          await getDatabase().ref('transportCards/$cardId').update({
            'cardNumber': cardNumber,
            'cardImageBase64': cardImageBase64,
            'userName': widget.userName,
            'route': widget.routeName,
            'regId': widget.regId,
            'uploadedAt': ServerValue.timestamp,
            'uploadedBy': adminUid,
          });
        }
      } else {
        // Create new card
        final newRef = getDatabase().ref('transportCards').push();
        await newRef.set({
          'userId': widget.userId,
          'userName': widget.userName,
          'route': widget.routeName,
          'regId': widget.regId,
          'cardNumber': cardNumber,
          'cardImageBase64': cardImageBase64 ?? '',
          'issueDate': ServerValue.timestamp,
          'expiry': DateTime.now()
              .add(const Duration(days: 365))
              .millisecondsSinceEpoch,
          'valid': true,
          'uploadedAt': ServerValue.timestamp,
          'uploadedBy': adminUid,
        });
      }

      if (!mounted) return;
      CustomSnackbar.success(context, 'Card uploaded successfully!');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        CustomSnackbar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Transport Card'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.08),
                            AppColors.primaryLight.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person,
                                  color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('User Details',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const Divider(height: 20),
                          _infoRow('Name', widget.userName),
                          _infoRow('Reg ID', widget.regId),
                          _infoRow('Route', widget.routeName),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card number field
                    TextField(
                      controller: _cardNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Card Number (optional)',
                        hintText: 'Auto-generated if empty',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Existing card preview
                    if (_existingCard != null &&
                        _existingCard!['cardImageBase64'] != null &&
                        _existingCard!['cardImageBase64'].toString().isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Existing Card Image',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(
                                  _existingCard!['cardImageBase64']),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: Icon(Icons.broken_image)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Image picker
                    const Text('Card Image (Required)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
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
                                  Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 44,
                                      color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select card image',
                                      style:
                                          TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (kIsWeb)
                                      Image.network(_pickedImage!.path,
                                          fit: BoxFit.cover)
                                    else
                                      Image.file(File(_pickedImage!.path),
                                          fit: BoxFit.cover),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _pickedImage = null),
                                        child: Container(
                                          padding:
                                              const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              color: Colors.white,
                                              size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    LoadingButton(
                      label: 'Upload Card',
                      isLoading: _isUploading,
                      icon: Icons.upload_rounded,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}