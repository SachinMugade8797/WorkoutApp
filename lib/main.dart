import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'services/exercise_data_service.dart';
import 'repositories/user_profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await ExerciseDataService.initialize();

  // Create + seed the SQLite database on startup. Wrapped so the app still
  // boots on platforms where the database file can't be opened.
  //
  // The catch is logged rather than silent: a failure here means recorded
  // workouts are not being persisted, which must not pass unnoticed.
  try {
    await UserProfileRepository.initialize();
    // Carry progress earned before the report used the database into
    // workout_history, so the Report tab isn't empty on first open.
    await ReportDataSource.backfillLegacyProgress();
  } catch (error, stack) {
    // Database unavailable — the app continues with local preferences only.
    debugPrint('Startup database init failed: $error\n$stack');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// MainNavigation - NO CHANGES NEEDED HERE
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  /// Lets a tab react to becoming the visible one. Needed because an
  /// `IndexedStack` keeps every tab alive, so a tab's `initState` never runs
  /// again and it is never rebuilt on tab switches.
  final ValueNotifier<int> _activeTab = ValueNotifier<int>(0);

  late final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    ReportScreen(tabIndex: 2, activeTab: _activeTab),
    const SettingsScreen(),
  ];

  @override
  void dispose() {
    _activeTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() {
            _currentIndex = index;
            _activeTab.value = index;
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey.shade500,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              activeIcon: Icon(Icons.timer),
              label: 'Training',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}