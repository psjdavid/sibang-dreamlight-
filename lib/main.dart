import 'package:flutter/material.dart';
import 'main_page.dart';
import 'settings_page.dart';
import 'sleep_analysis_page.dart';
import 'asleep_service.dart';
import 'sleep_tracking_service.dart';

final AsleepService asleepService = AsleepService(
  apiKey: '0MlUUm49iPbsko2ovZ8tRmc9IRFP4lbuJIEu2RIt',
  userId: 'G-20251117131004-SiPSocWbnDOkBygUrGDB',
);

final SleepTrackingService sleepTrackingService = SleepTrackingService(
  asleepService: asleepService,
);

void main() {
  runApp(const DreamLightApp());
}

class DreamLightApp extends StatefulWidget {
  const DreamLightApp({super.key});

  @override
  State<DreamLightApp> createState() => _DreamLightAppState();
}

class _DreamLightAppState extends State<DreamLightApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '드림라이트',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5FF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigation(
        isDarkMode: _isDarkMode,
        onThemeToggle: toggleTheme,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const MainNavigation({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // 기본값은 메인 페이지 (가운데)

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SettingsPage(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      const MainPage(),
      const SleepAnalysisPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '설정',
            ),
            NavigationDestination(
              icon: Icon(Icons.alarm_outlined),
              selectedIcon: Icon(Icons.alarm),
              label: '알람',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: '수면 분석',
            ),
          ],
        ),
      ),
    );
  }
}