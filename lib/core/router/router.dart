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

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

/// Provider to check if current user is a member of a crew
final crewMembershipProvider = FutureProvider.family<Member?, String>((ref, crewId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.read(memberRepositoryProvider);
  return await repo.getMember(crewId, user.uid);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/hub',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
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
    final memberAsync = ref.watch(crewMembershipProvider(crewId));
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isPendingPage = currentPath.endsWith('/pending');

    return memberAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (member) {
        // Not a member and not on pending page -> redirect to pending
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
