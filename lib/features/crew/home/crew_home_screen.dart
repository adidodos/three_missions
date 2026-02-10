import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/router.dart';
import 'crew_home_provider.dart';
import 'widgets/week_calendar.dart';

class CrewHomeScreen extends ConsumerWidget {
  final String crewId;

  const CrewHomeScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewAsync = ref.watch(crewDetailProvider(crewId));
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider(crewId));
    final memberAsync = ref.watch(crewMembershipProvider(crewId));

    return Scaffold(
      appBar: AppBar(
        title: crewAsync.when(
          loading: () => const Text('...'),
          error: (_, __) => const Text('크루'),
          data: (crew) => Text(crew?.name ?? '크루'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/hub'),
        ),
        actions: [
          // Admin menu
          if (memberAsync.value?.role.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/crew/$crewId/manage'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayWorkoutProvider(crewId));
          ref.invalidate(myWeekWorkoutsProvider(crewId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today status
            _TodayStatusCard(crewId: crewId),
            const SizedBox(height: 16),

            // Week calendar
            WeekCalendar(crewId: crewId),
            const SizedBox(height: 16),

            // Weekly mission status
            _WeeklyMissionCard(crewId: crewId),
            const SizedBox(height: 24),

            // Navigation buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/crew/$crewId/table'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('주간표'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/crew/$crewId/stats'),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('내 통계'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: todayWorkoutAsync.when(
        loading: () => null,
        error: (_, __) => null,
        data: (workout) => FloatingActionButton.extended(
          onPressed: () => context.push('/crew/$crewId/workout'),
          icon: Icon(workout != null ? Icons.edit : Icons.add),
          label: Text(workout != null ? '인증 수정' : '오늘 인증하기'),
        ),
      ),
    );
  }
}

class _TodayStatusCard extends ConsumerWidget {
  final String crewId;

  const _TodayStatusCard({required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayWorkoutAsync = ref.watch(todayWorkoutProvider(crewId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            todayWorkoutAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (workout) {
                if (workout == null) {
                  return Row(
                    children: [
                      Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('아직 인증하지 않았습니다'),
                    ],
                  );
                }

                return Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${workout.type} 인증 완료!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (workout.memo != null && workout.memo!.isNotEmpty)
                            Text(
                              workout.memo!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyMissionCard extends ConsumerWidget {
  final String crewId;

  const _WeeklyMissionCard({required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(myWeekWorkoutsProvider(crewId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: workoutsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('오류: $e'),
          data: (workouts) {
            final count = workouts.length;
            final isSuccess = count >= 3;
            final remaining = 3 - count;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '이번 주 미션',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isSuccess ? '성공!' : '$remaining회 남음',
                        style: TextStyle(
                          color: isSuccess
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (count / 3).clamp(0.0, 1.0),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Text(
                  '$count / 3 회 인증',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
