import 'package:flutter/material.dart';

class SummaryPanel extends StatelessWidget {
  final Locale currentLocale;

  const SummaryPanel({
    super.key,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEn = currentLocale.languageCode == 'en';
    
    return Center(
      child: Text(
        isEn ? 'Coming Soon' : 'Yakında Sizlerle',
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}