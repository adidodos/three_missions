import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/logs/presentation/screens/home_screen.dart';
import '../../features/logs/presentation/screens/logs_screen.dart';
import '../../features/logs/presentation/screens/add_log_screen.dart';
import '../../features/logs/presentation/screens/edit_log_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/members/presentation/screens/members_screen.dart';
import '../../features/exercise_types/presentation/screens/exercise_types_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/logs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/logs/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddLogScreen(),
    ),
    GoRoute(
      path: '/logs/edit/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => EditLogScreen(
        logId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/stats',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/settings/members',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MembersScreen(),
    ),
    GoRoute(
      path: '/settings/exercise-types',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExerciseTypesScreen(),
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/logs')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/logs');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}
