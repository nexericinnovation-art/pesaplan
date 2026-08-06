import 'package:flutter/material.dart';

/// Used for profile settings tiles that don't have a real feature behind
/// them yet (Account Security, Notifications, Appearance). Tells the user
/// plainly that it isn't built, instead of a tile that silently does
/// nothing when tapped.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction_outlined, size: 48, color: Colors.black38),
                const SizedBox(height: 16),
                Text(
                  "$title isn't built yet.",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: Colors.black54), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
