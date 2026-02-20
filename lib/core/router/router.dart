import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../repositories/member_repository.dart';
import '../models/member.dart';

import '../../features/login/login_screen.dart';
import '../../features/hub/hub_screen.dart';
import '../../features/crew/join/crew_search_screen.dart';
import '../../features/crew/pending/pending_screen.dart';
import '../../features/crew/home/crew_home_screen.dart';
import '../../features/crew/home/workout_form_screen.dart';
import '../../features/crew/table/crew_table_screen.dart';
import '../../features/crew/stats/stats_screen.dart';
import '../../features/crew/manage/manage_screen.dart';
import '../../features/crew/members/members_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/inquiry/inquiry_screen.dart';
import '../../features/settings/inquiry/inquiry_admin_screen.dart';
import '../../features/settings/neighborhood/neighborhood_screen.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

/// Provider to check if current user is a member of a crew.
/// Watches [currentUidProvider] (a String?) instead of [currentUserProvider]
/// so it does NOT re-execute when Firebase re-emits the same user as a new
/// object (e.g. on app resume from camera). This keeps [CrewMembershipGuard]
/// stable while the camera/gallery picker is active.
final crewMembershipProvider = FutureProvider.family<Member?, String>((ref, crewId) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;

  final repo = ref.read(memberRepositoryProvider);
  return await repo.getMember(crewId, uid);
});

/// Bridges Riverpod auth stream → GoRouter refreshListenable without
/// recreating the GoRouter instance on every auth event.
class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  _AuthNotifier(Ref ref) {
    _sub = ref.read(authRepositoryProvider).authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/hub',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final user = ref.read(authRepositoryProvider).currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Not logged in -> go to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // Logged in but on login page -> go to hub
      if (isLoggedIn && isLoggingIn) {
        return '/hub';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/hub',
        builder: (context, state) => const HubScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/inquiry',
        builder: (context, state) => const InquiryScreen(),
      ),
      GoRoute(
        path: '/settings/inquiry/admin',
        builder: (context, state) => const InquiryAdminScreen(),
      ),
      GoRoute(
        path: '/settings/neighborhood',
        builder: (context, state) => const NeighborhoodScreen(),
      ),
      GoRoute(
        path: '/crew/search',
        builder: (context, state) => const CrewSearchScreen(),
      ),
      // Crew routes with membership check
      ShellRoute(
        builder: (context, state, child) {
          // Extract crewId from path
          final crewId = state.pathParameters['id'];
          if (crewId == null) return child;

          return CrewMembershipGuard(crewId: crewId, child: child);
        },
        routes: [
          GoRoute(
            path: '/crew/:id/pending',
            builder: (context, state) => PendingScreen(
              crewId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/crew/:id',
            builder: (context, state) => CrewHomeScreen(
              crewId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'workout',
                builder: (context, state) => WorkoutFormScreen(
                  crewId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'table',
                builder: (context, state) => CrewTableScreen(
                  crewId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'stats',
                builder: (context, state) => StatsScreen(
                  crewId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'members',
                builder: (context, state) => MembersScreen(
                  crewId: state.pathParameters['id']!,
                ),
              ),
              GoRoute(
                path: 'manage',
                builder: (context, state) => ManageScreen(
                  crewId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Widget that checks crew membership and redirects if needed
class CrewMembershipGuard extends ConsumerWidget {
  final String crewId;
  final Widget child;

  const CrewMembershipGuard({
    super.key,
    required this.crewId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final memberAsync = ref.watch(crewMembershipProvider(crewId));
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isPendingPage = currentPath.endsWith('/pending');

    // Auth is still loading — don't redirect yet
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return memberAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (member) {
        // Not a member and not on pending page -> redirect to pending
        // (user != null is guaranteed above, so this is a genuine non-member case)
        if (member == null && !isPendingPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/crew/$crewId/pending');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Is a member but on pending page -> redirect to crew home
        if (member != null && isPendingPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/crew/$crewId');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check admin access for manage page
        if (currentPath.endsWith('/manage') && member != null && !member.role.isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/crew/$crewId');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return child;
      },
    );
  }
}
