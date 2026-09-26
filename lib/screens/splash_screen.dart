import 'package:flutter/material.dart';

import 'welcome_screen.dart';

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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()));
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
                colors: [Colors.blue, Colors.purple])),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/comsats_logo.png',
                height: 120,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, size: 100, color: Colors.white)),
            const SizedBox(height: 20),
            const Text('Campus Move',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Text('COMSATS University Sahiwal',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ]),
        ),
      ),
    );
  }
}