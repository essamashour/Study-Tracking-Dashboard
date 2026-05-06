import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'courses_screen.dart';
import 'tasks_screen.dart';
import 'progress_screen.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  /// Only the visible tab is built so Firestore streams and heavy lists are not
  /// all active at once (IndexedStack would keep every tab mounted).
  Widget _bodyForIndex(int i) {
    switch (i) {
      case 0:
        return const CoursesScreen();
      case 1:
        return const TasksScreen();
      case 2:
      default:
        return const ProgressScreen();
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await _authService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final currentBrightness = Theme.of(context).brightness;
    final effectiveDark = switch (appThemeMode.value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => currentBrightness == Brightness.dark,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: effectiveDark ? 'وضع فاتح' : 'وضع داكن',
            onPressed: () => toggleAppTheme(currentBrightness: currentBrightness),
            icon: Icon(effectiveDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _bodyForIndex(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'الكورسات',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'المهام',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'التقدم',
          ),
        ],
      ),
    );
  }
}