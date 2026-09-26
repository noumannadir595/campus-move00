import 'package:flutter/material.dart';

class Hover3DCard extends StatefulWidget {
  final Widget child;
  const Hover3DCard({super.key, required this.child});
  @override
  State<Hover3DCard> createState() => _Hover3DCardState();
}

class _Hover3DCardState extends State<Hover3DCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isHovered ? 1.02 : 1.0,
        child: widget.child,
      ),
    );
  }
}