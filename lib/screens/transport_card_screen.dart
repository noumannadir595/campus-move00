import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/database.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email mismatch')));
      return;
    }
    if (_passwordController.text.trim() != user.email) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid password')));
      return;
    }
    setState(() => _isLoading = true);
    final uid = user.uid;
    final appSnap = await getDatabase()
        .ref('applications')
        .orderByChild('userId')
        .equalTo(uid)
        .get();
    if (!appSnap.exists) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No application')));
      setState(() => _isLoading = false);
      return;
    }
    final apps = appSnap.value as Map<dynamic, dynamic>;
    if (apps.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No application')));
      setState(() => _isLoading = false);
      return;
    }
    final app = apps.values.first;
    if (app['paymentStatus'] != 'paid') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment not verified yet.')));
      setState(() => _isLoading = false);
      return;
    }
    final cardSnap = await getDatabase()
        .ref('transportCards')
        .orderByChild('userId')
        .equalTo(uid)
        .get();
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
      'expiry':
          DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
      'valid': true
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32)),
            margin: const EdgeInsets.all(24),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.credit_card, size: 60, color: Colors.white),
                const Text('Campus Move',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Card #: ${_cardData!['cardNumber']}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Text(
                    'Valid till: ${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(_cardData!['expiry']))}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                const Icon(Icons.qr_code_scanner,
                    size: 80, color: Colors.white),
              ]),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Transport Card')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Your Email', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password (use email as password)',
                  border: OutlineInputBorder())),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: _generateCard,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Card')),
        ]),
      ),
    );
  }
}