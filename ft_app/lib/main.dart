import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ft_app/features/cows/presentation/_showRegisterCowSheet.dart';
import 'features/settings/presentation/settings_panel.dart';
import 'features/summary/presentation/summary_panel.dart';
import 'features/cows/presentation/animal_panel.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine bindings are established before calling native code plugins
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load persistent preferences from local device storage
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Read the saved locale key, fallback to English ('en') if it doesn't exist yet
  final String savedLanguageCode = prefs.getString('language_code') ?? 'en';

  runApp(MyApp(initialLocale: Locale(savedLanguageCode)));
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _currentLocale;

  @override
  void initState() {
    super.initState();
    // Assign the cached locale passed from main execution block
    _currentLocale = widget.initialLocale;
  }

  // 🌍 Global persistent application locale state updater
  void _updateLanguage(String langCode) async {
    setState(() {
      _currentLocale = Locale(langCode);
    });

    // Commit the language choice to persistent disk memory asynchronously
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: _currentLocale, 
      home: HomeScreen(
        currentLocale: _currentLocale,
        onLanguageChanged: _updateLanguage,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Locale currentLocale;
  final Function(String) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.currentLocale,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bool isEn = widget.currentLocale.languageCode == 'en';
    final List<Widget> panels = [
      SummaryPanel(currentLocale: widget.currentLocale),
      AnimalPanel(currentLocale: widget.currentLocale),
    ];
    
    final String appTitle = isEn ? "Cengiz Ciftlik" : "Cengiz Ciftlik";
    final String menuHeader = isEn ? "System Menu" : "Sistem Menüsü";
    final String settingsLabel = isEn ? "Settings" : "Ayarlar";
    final String summaryLabel = isEn ? "Summary" : "Özet";
    final String animalsLabel = isEn ? "Animals" : "Hayvanlar";
    final String addCowLabel = isEn ? "Add Cow" : "İnek Ekle";

    final int bodyIndex = (_currentIndex >= panels.length) ? 0 : _currentIndex;

    return Scaffold(
        appBar: AppBar(
          title: Text(appTitle),
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF0F172A),
          child: ListView(
            children: [
              Container(
                color: const Color(0xFF020617),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            menuHeader,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF2DD4BF)),
                title: Text(settingsLabel),
                onTap: () {
                  Navigator.pop(context); 
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPanel(
                        currentLocale: widget.currentLocale,
                        onLanguageChanged: widget.onLanguageChanged,
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
        body: panels[bodyIndex],
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: const Color(0xFF020617),
                onPressed: () {
                  showRegisterCowSheet(context, widget.currentLocale);
                },
                label: Text(addCowLabel),
                icon: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF2DD4BF),
          unselectedItemColor: Colors.white38,
          currentIndex: bodyIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart),
              label: summaryLabel,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pets),
              label: animalsLabel,
            ),
          ],
        ));
  }
}