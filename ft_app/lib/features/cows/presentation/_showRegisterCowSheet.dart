import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void showRegisterCowSheet(BuildContext context, Locale currentLocale) {
  final bool isTr = currentLocale.languageCode == 'tr';

  final TextEditingController tagController = TextEditingController();
  final TextEditingController dobController = TextEditingController(); // Date of birth
  final TextEditingController damController = TextEditingController();
  final TextEditingController sireController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController lcdController = TextEditingController(); // Last calving date

  // Initial drop down value state configuration
  String reproductiveStatus = 'In Lactation';
  String gender = 'Female';

  // Helper method to show calendar and set date to the given controller
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Theme overrides to maintain the strict Tailwind dark slate / teal look
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF14B8A6), // teal-500 for active accents
              onPrimary: Color(0xFF020617), // text-slate-950 inside active button
              surface: Color(0xFF0F172A), // bg-slate-900 calendar body
              onSurface: Colors.white, // Text color inside the body
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Formats date cleanly to YYYY-MM-DD format
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, 
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // bg-slate-900
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1.5), // border-slate-800
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 8,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Swipe Indicator Accent
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155), // slate-700
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Component Header Row Matrix
                Row(
                  children: [
                    const Icon(Icons.add_circle, color: Color(0xFF2DD4BF), size: 16), 
                    const SizedBox(width: 6),
                    Text(
                      isTr ? "YENİ SIĞIR KAYDI EKLE" : "REGISTER NEW CATTLE",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Color(0xFF1E293B), height: 1), 
                ),

                // Form Layout Rows System
                Row(
                  children: [
                    Expanded(child: _buildDarkInputField(isTr ? "Küpe Numarası Kimliği" : "Tag Number Identifier", tagController)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDarkInputField(
                        isTr ? "Doğum Tarihi" : "Date of Birth", 
                        dobController,
                        placeholder: "YYYY-MM-DD",
                        suffixIcon: Icons.calendar_today,
                        readOnly: true, // Prevents keyboard from appearing
                        onTap: () => _selectDate(context, dobController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDarkInputField(isTr ? "Anne Soyu" : "Dam Line", damController)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDarkInputField(isTr ? "Baba Soyu" : "Sire Line", sireController, isMono: true)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDarkDropdownField(
                        isTr ? "Durum" : "Status",
                        currentValue: reproductiveStatus,
                        items: const ['In Lactation', 'Open', 'Dry Period', 'Pregnant'],
                        displayMap: isTr ? {
                          'In Lactation': 'Laktasyonda',
                          'Open': 'Açık / Boş',
                          'Dry Period': 'Kuru Dönem',
                          'Pregnant': 'Gebe',
                        } : null,
                        onChanged: (val) {
                          setModalState(() {
                            reproductiveStatus = val!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDarkDropdownField(
                        isTr ? "Cinsiyet" : "Sex",
                        currentValue: gender,
                        items: const ['Female', 'Male'],
                        displayMap: isTr ? {
                          'Female': 'Dişi',
                          'Male': 'Erkek',
                        } : null,
                        onChanged: (val) {
                          setModalState(() {
                            gender = val!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDarkInputField(isTr ? "Irk" : "Breed", breedController, isMono: true)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDarkInputField(
                        isTr ? "Son Buzağılama Tarihi" : "Last Calving Date", 
                        lcdController,
                        placeholder: "YYYY-MM-DD",
                        suffixIcon: Icons.calendar_today,
                        isMono: true,
                        readOnly: true, // Prevents keyboard from appearing
                        onTap: () => _selectDate(context, lcdController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Commit Action Trigger
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6), 
                      foregroundColor: const Color(0xFF020617), 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () async {
                      final String earTag = tagController.text.trim();
                      if (earTag.isEmpty) return;

                      try {
                        final url = Uri.parse('http://localhost:5000/api/cows'); //10.0.2.2 on android emulator and localhost on web
                        final response = await http.post(
                          url,
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "tagNumber": earTag,
                            "status": reproductiveStatus,
                            "birthDate": dobController.text.trim(),
                            "damLine": damController.text.trim(),
                            "sireLine": sireController.text.trim(),
                            "breed": breedController.text.trim(),
                            "sex": gender, 
                            "lastCalvingDate": lcdController.text.trim(),
                          }),
                        );

                        if (response.statusCode == 201 || response.statusCode == 200) {
                          Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr 
                                  ? "$earTag küpeli sığır kaydı veri tabanına eklendi."
                                  : "Cow $earTag is registered inside the database."),
                                backgroundColor: const Color(0xFF14B8A6),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isTr ? "Ağ hatası: $e" : "Network failure: $e"), 
                              backgroundColor: Colors.redAccent
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      isTr ? "Kayıt Defterine Ekle" : "Add Cattle",
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      );
    },
  );
}

// Custom Builder Helper for Slate Input Form Styling
Widget _buildDarkInputField(
  String label, 
  TextEditingController controller, {
  String? placeholder, 
  bool isMono = false,
  bool readOnly = false,
  VoidCallback? onTap,
  IconData? suffixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace'), 
      ),
      const SizedBox(height: 3),
      SizedBox(
        height: 34,
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: isMono ? 'monospace' : null,
            fontWeight: isMono ? FontWeight.bold : FontWeight.normal,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF020617), 
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11), 
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 12, color: const Color(0xFF64748B)) : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF1E293B)), 
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF14B8A6)), 
            ),
          ),
        ),
      ),
    ],
  );
}

// Custom Builder Helper for the Dropdown Selection Component with optional Display Map localization support
Widget _buildDarkDropdownField(
  String label, {
  required String currentValue, 
  required List<String> items, 
  Map<String, String>? displayMap,
  required ValueChanged<String?> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontFamily: 'monospace'),
      ),
      const SizedBox(height: 3),
      SizedBox(
        height: 34,
        child: DropdownButtonFormField<String>(
          value: currentValue,
          dropdownColor: const Color(0xFF0F172A), 
          style: const TextStyle(color: Colors.white, fontSize: 11),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF020617),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF14B8A6)),
            ),
          ),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(displayMap != null ? (displayMap[value] ?? value) : value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    ],
  );
}