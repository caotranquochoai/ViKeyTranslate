import 'package:flutter/material.dart';

class FloatingBubble extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingBubble({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.translate, color: Colors.white),
        ),
      ),
    );
  }
}
