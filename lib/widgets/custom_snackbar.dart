import 'package:flutter/material.dart';

class CustomSnackbar {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade600, Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade600, Icons.error_rounded);
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, Colors.orange.shade700, Icons.warning_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Colors.blue.shade600, Icons.info_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}