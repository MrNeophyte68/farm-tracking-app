import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class AnimalPanel extends StatefulWidget {
  final Locale currentLocale;
  
  const AnimalPanel({
    super.key,
    required this.currentLocale,
  });

  @override
  State<AnimalPanel> createState() => _AnimalPanelState();
}

class _AnimalPanelState extends State<AnimalPanel> {
  late final WebSocketChannel _channel;
  final List<Map<String, dynamic>> _cows = [];
  final TextEditingController _searchController = TextEditingController();
  
  final String _apiUrl = 'https://farm-tracking-app.onrender.com/api/cows';
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://farm-tracking-app.onrender.com'),
    );

    _channel.stream.listen(
      (message) {
        _handleWebSocketMessage(message);
      },
      onError: (error) {
        debugPrint("WebSocket Pipeline Error: $error");
      },
    );

    _searchController.addListener(() => setState(() {}));
  }

  void _handleWebSocketMessage(dynamic rawData) {
    try {
      final response = jsonDecode(rawData.toString());
      final String event = response['event'] ?? '';
      final dynamic data = response['data'];

      setState(() {
        if (event == 'initialCows') {
          _cows.clear();
          for (var item in data) {
            _cows.add(Map<String, dynamic>.from(item));
          }
          _hasLoadedInitialData = true;
        } else if (event == 'newCow') {
          final String newId = data['_id'] ?? '';
          if (!_cows.any((c) => c['_id'] == newId)) {
            _cows.add(Map<String, dynamic>.from(data));
          }
        } else if (event == 'updateCow') {
          final idx = _cows.indexWhere((c) => c['_id'] == data['_id']);
          if (idx != -1) {
            _cows[idx].addAll(Map<String, dynamic>.from(data));
          }
        } else if (event == 'deleteCow') {
          _cows.removeWhere((c) => c['_id'] == data['_id']);
        }
      });
    } catch (e) {
      debugPrint("Error processing socket transmission payload: $e");
    }
  }

  Future<void> _deleteCowFromDatabase(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/$id'));
      if (response.statusCode != 200) {
        if (mounted) {
          final bool isTr = widget.currentLocale.languageCode == 'tr';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isTr ? 'İnek kaydı sunucudan silinemedi.' : 'Failed to delete cow backend record.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending HTTP DELETE request: $e");
    }
  }

  void _showDeleteConfirmation(String id, String tagNumber) {
    final bool isTr = widget.currentLocale.languageCode == 'tr';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          isTr ? 'İnek #$tagNumber Silinsin mi?' : 'Delete Cow #$tagNumber?', 
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isTr ? 'Bu hayvanı sicil kaydından silmek istediğinize emin misiniz?' : 'Are you sure you want to remove this animal from the registry?', 
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isTr ? 'İptal' : 'Cancel', style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              _deleteCowFromDatabase(id);
              Navigator.pop(context);
            },
            child: Text(isTr ? 'Sil' : 'Delete', style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF14B8A6), 
              onPrimary: Color(0xFF020617), 
              surface: Color(0xFF0F172A), 
              onSurface: Colors.white, 
            ),
            dialogBackgroundColor: const Color(0xFF0F172A),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  void _showCreateSheet() {
    final bool isTr = widget.currentLocale.languageCode == 'tr';
    
    final TextEditingController tagController = TextEditingController();
    final TextEditingController damController = TextEditingController();
    final TextEditingController sireController = TextEditingController();
    final TextEditingController breedController = TextEditingController();
    final TextEditingController dobController = TextEditingController();
    final TextEditingController lcdController = TextEditingController();

    String reproductiveStatus = 'In Lactation';
    String gender = 'Female';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155), 
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.add_box_outlined, color: Color(0xFF2DD4BF), size: 16), 
                      const SizedBox(width: 6),
                      Text(
                        isTr ? "YENİ SIĞIR KAYDI EKLE" : "REGISTER NEW CATTLE PROFILE",
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
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Color(0xFF1E293B), height: 1)),
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
                          readOnly: true, 
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
                          readOnly: true, 
                          onTap: () => _selectDate(context, lcdController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          final response = await http.post(
                            Uri.parse(_apiUrl),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr 
                                  ? "$earTag küpeli sığır kaydı başarıyla oluşturuldu."
                                  : "Cow $earTag profiling records successfully created."),
                                backgroundColor: const Color(0xFF14B8A6),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr ? "Sunucu kaydı reddetti: ${response.body}" : "Server rejected submission: ${response.body}"), 
                                backgroundColor: Colors.redAccent
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isTr ? "Ağ hatası: $e" : "Network failure: $e"), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: Text(
                        isTr ? "Kayıt Defterine Ekle" : "Add to Registry",
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

  void _showEditSheet(Map<String, dynamic> cow) {
    final bool isTr = widget.currentLocale.languageCode == 'tr';
    final String mongoId = cow['_id'] ?? '';
    
    final TextEditingController tagController = TextEditingController(text: cow['tagNumber'] ?? '');
    final TextEditingController damController = TextEditingController(text: cow['damLine'] ?? '');
    final TextEditingController sireController = TextEditingController(text: cow['sireLine'] ?? '');
    final TextEditingController breedController = TextEditingController(text: cow['breed'] ?? '');
    
    final TextEditingController dobController = TextEditingController();
    if (cow['birthDate'] != null) {
      try {
        dobController.text = DateTime.parse(cow['birthDate'].toString()).toIso8601String().split('T')[0];
      } catch (_) {}
    }
    
    final TextEditingController lcdController = TextEditingController();
    if (cow['lastCalvingDate'] != null) {
      try {
        lcdController.text = DateTime.parse(cow['lastCalvingDate'].toString()).toIso8601String().split('T')[0];
      } catch (_) {}
    }

    String reproductiveStatus = ['In Lactation', 'Open', 'Dry Period', 'Pregnant'].contains(cow['status']) 
        ? cow['status'] 
        : 'In Lactation';
        
    String gender = ['Female', 'Male'].contains(cow['sex']) 
        ? cow['sex'] 
        : 'Female';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1.5)),
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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155), 
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.edit_calendar, color: Color(0xFF2DD4BF), size: 16), 
                      const SizedBox(width: 6),
                      Text(
                        isTr ? "SIĞIR PROFİLİNİ DÜZENLE (#${cow['tagNumber']})" : "EDIT CATTLE PROFILE (#${cow['tagNumber']})",
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
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Color(0xFF1E293B), height: 1)),
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
                          readOnly: true, 
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
                          readOnly: true, 
                          onTap: () => _selectDate(context, lcdController),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          final url = Uri.parse('$_apiUrl/$mongoId'); 
                          final response = await http.put(
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

                          if (response.statusCode == 200) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr 
                                  ? "$earTag küpeli inek kayıtları başarıyla güncellendi."
                                  : "Cow $earTag profiling records successfully updated."),
                                backgroundColor: const Color(0xFF14B8A6),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr ? "Sunucu değişikliği reddetti: ${response.body}" : "Server rejected modification: ${response.body}"), 
                                backgroundColor: Colors.redAccent
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isTr ? "Ağ hatası: $e" : "Network failure: $e"), backgroundColor: Colors.redAccent),
                          );
                        }
                      },
                      child: Text(
                        isTr ? "Değişiklikleri Kaydet" : "Save Modifications",
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pregnant': return const Color(0xFFB45309);
      case 'open': return const Color(0xFF1D4ED8);
      default: return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTr = widget.currentLocale.languageCode == 'tr';

    if (!_hasLoadedInitialData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF2DD4BF))),
            const SizedBox(height: 16),
            Text(
              isTr ? 'EyeNeck sunucusuna bağlanılıyor...' : 'Connecting to EyeNeck server...', 
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (_cows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: const Color(0xFF2DD4BF).withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              isTr ? 'Sığır Kaydı Bulunamadı' : 'No Cattle Records Found',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isTr ? 'İlk hayvanınızı kaydetmek için aşağıdaki düğmeye dokunun.' : 'Tap the button below to register your first animal.',
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6), foregroundColor: const Color(0xFF020617)),
              onPressed: _showCreateSheet,
              icon: const Icon(Icons.add),
              label: Text(isTr ? "İnek Ekle" : "Add Cow"),
            )
          ],
        ),
      );
    }

    final String searchTerms = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filteredCows = _cows.where((cow) {
      final String tag = (cow['tagNumber'] ?? '').toString().toLowerCase();
      return tag.contains(searchTerms);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 4.0),
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: isTr ? "Küpeli İnek Numarası ile Ara..." : "Search by Cow Tag Identifier...",
                hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF2DD4BF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2DD4BF)),
                ),
              ),
            ),
          ),
        ),
        
        Expanded(
          child: filteredCows.isEmpty
              ? Center(
                  child: Text(
                    isTr ? '"$searchTerms" için eşleşme bulunamadı' : 'No matches found for "$searchTerms"',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  itemCount: filteredCows.length,
                  itemBuilder: (context, index) {
                    final cow = filteredCows[index];
                    final String mongoId = cow['_id'] ?? '';
                    final String tagNumber = cow['tagNumber'] ?? 'Unknown';
                    final String status = cow['status'] ?? 'Unknown';
                    final String breed = cow['breed'] ?? 'N/A';
                    final String sex = cow['sex'] ?? 'N/A';
                    final String damLine = cow['damLine'] ?? 'N/A';
                    final String sireLine = cow['sireLine'] ?? 'N/A';

                    String displayStatus = status;
                    if (isTr) {
                      switch (status) {
                        case 'In Lactation': displayStatus = 'Laktasyonda'; break;
                        case 'Open': displayStatus = 'Açık / Boş'; break;
                        case 'Dry Period': displayStatus = 'Kuru Dönem'; break;
                        case 'Pregnant': displayStatus = 'Gebe'; break;
                      }
                    }

                    String displaySex = sex;
                    if (isTr) {
                      if (sex == 'Female') displaySex = 'Dişi';
                      if (sex == 'Male') displaySex = 'Erkek';
                    }

                    String birthDate = '-- / --';
                    if (cow['birthDate'] != null) {
                      try {
                        DateTime dt = DateTime.parse(cow['birthDate'].toString());
                        birthDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                      } catch (_) {}
                    }

                    String lastCalvingDate = '-- / --';
                    if (cow['lastCalvingDate'] != null) {
                      try {
                        DateTime dt = DateTime.parse(cow['lastCalvingDate'].toString());
                        lastCalvingDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                      } catch (_) {}
                    }

                    return Container(
                      key: ValueKey(mongoId),
                      margin: const EdgeInsets.only(bottom: 14.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2DD4BF),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2DD4BF).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF2DD4BF)),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              sex.toLowerCase() == 'male' ? Icons.male : Icons.pets,
                                              color: const Color(0xFF2DD4BF),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isTr ? 'KÜPE NUMARASI' : 'EAR TAG', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                                            Text(tagNumber, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: _getStatusColor(status), borderRadius: BorderRadius.circular(20)),
                                          child: Text(displayStatus, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                                          onPressed: () => _showEditSheet(cow),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                          onPressed: () => _showDeleteConfirmation(mongoId, tagNumber),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Divider(color: Colors.white10, height: 1)),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.5,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  children: [
                                    _buildInfoBlock(isTr ? 'Irk' : 'Breed', breed),
                                    _buildInfoBlock(isTr ? 'Cinsiyet' : 'Sex', displaySex),
                                    _buildInfoBlock(isTr ? 'Doğum Tarihi' : 'Birth Date', birthDate),
                                    _buildInfoBlock(isTr ? 'Son Buzağılama' : 'Last Calving', lastCalvingDate),
                                    _buildInfoBlock(isTr ? 'Anne Soyu' : 'Dam Line', damLine),
                                    _buildInfoBlock(isTr ? 'Baba Soyu' : 'Sire Line', sireLine),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF020617).withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _channel.sink.close();
    super.dispose();
  }
}

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
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B), size: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF020617),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF1E293B)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF14B8A6)),
            ),
          ),
          items: items.map((String value) {
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