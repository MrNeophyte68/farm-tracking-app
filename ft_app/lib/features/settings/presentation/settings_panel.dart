import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  final Locale currentLocale;
  final Function(String) onLanguageChanged;

  const SettingsPanel({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String currentLang = currentLocale.languageCode;
    final bool isEn = currentLang == 'en';

    // Quick inline translation mapping for this screen
    final String titleText = isEn ? "Settings" : "Ayarlar";
    final String bodyText = isEn 
        ? "System Configuration Settings Dashboard" 
        : "Sistem Yapılandırma Ayarları Paneli";
    final String languageLabel = isEn ? "Change Language" : "Dili Değiştir";
    final String activeLabel = isEn ? "English Active" : "Türkçe Aktif";

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Fits your deep dark theme
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  bodyText,
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            // Language Selection Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageLabel,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeLabel,
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  
                  // Language Toggle Switch Buttons
                  Row(
                    children: [
                      _buildLangButton(
                        label: "EN", 
                        isActive: isEn, 
                        onTap: () => onLanguageChanged('en'),
                      ),
                      const SizedBox(width: 6),
                      _buildLangButton(
                        label: "TR", 
                        isActive: !isEn, 
                        onTap: () => onLanguageChanged('tr'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangButton({required String label, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF020617),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? Colors.transparent : const Color(0xFF1E293B)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF020617) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}