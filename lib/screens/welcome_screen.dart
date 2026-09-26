import 'package:flutter/material.dart';

import 'home_wrapper.dart';

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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeWrapper()));
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
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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