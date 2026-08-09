import 'package:flutter/material.dart';

/// Displays a long-form legal document. Purely a text renderer — the actual
/// content lives in legal_content.dart, kept separate so the content can be
/// reviewed/edited independently of the display widget.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.title, required this.body, required this.lastUpdated});

  final String title;
  final String body;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last updated: $lastUpdated', style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 16),
              Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
