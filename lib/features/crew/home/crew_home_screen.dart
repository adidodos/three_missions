import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/crew_settings.dart';
import '../../../core/models/member.dart';
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

    final crew = crewAsync.value;
    final isSetupComplete = crew?.isSetupComplete ?? false;

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
          if (isSetupComplete && memberAsync.value?.role.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/crew/$crewId/manage'),
            ),
        ],
      ),
      body: crewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (crew) {
          if (crew == null) {
            return const Center(child: Text('크루를 찾을 수 없습니다'));
          }

          if (!crew.isSetupComplete) {
            final isOwner = memberAsync.value?.role == MemberRole.owner;
            if (isOwner) {
              return _SetupPrompt(crewId: crewId);
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(crewDetailProvider(crewId));
              },
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('크루장이 초기 설정을 진행 중입니다'),
                          const SizedBox(height: 8),
                          Text(
                            '잠시 후 다시 확인해주세요',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todayWorkoutProvider(crewId));
              ref.invalidate(myWeekWorkoutsProvider(crewId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TodayStatusCard(crewId: crewId),
                const SizedBox(height: 16),
                WeekCalendar(crewId: crewId),
                const SizedBox(height: 16),
                _WeeklyMissionCard(crewId: crewId),
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/crew/$crewId/members'),
                    icon: const Icon(Icons.group),
                    label: const Text('크루원 목록'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: !isSetupComplete
          ? null
          : todayWorkoutAsync.when(
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

class _SetupPrompt extends ConsumerStatefulWidget {
  final String crewId;

  const _SetupPrompt({required this.crewId});

  @override
  ConsumerState<_SetupPrompt> createState() => _SetupPromptState();
}

class _SetupPromptState extends ConsumerState<_SetupPrompt> {
  int _selectedGoal = 3;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '크루 초기 설정',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text('주간 미션 목표를 설정해주세요'),
          const SizedBox(height: 32),
          Text(
            '주 $_selectedGoal회',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            value: _selectedGoal.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: '$_selectedGoal회',
            onChanged: (v) => setState(() => _selectedGoal = v.round()),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('설정 완료'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(crewHomeRepositoryProvider);
      await repo.updateSettings(
        widget.crewId,
        CrewSettings(weeklyGoal: _selectedGoal),
      );
      ref.invalidate(crewDetailProvider(widget.crewId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                        Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.outline,
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
    final crew = ref.watch(crewDetailProvider(crewId)).value;
    final goal = crew?.settings?.weeklyGoal ?? 3;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: workoutsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('오류: $e'),
          data: (workouts) {
            final count = workouts.length;
            final isSuccess = count >= goal;
            final remaining = goal - count;

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
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isSuccess ? '성공!' : '$remaining회 남음',
                        style: TextStyle(
                          color: isSuccess
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (count / goal).clamp(0.0, 1.0),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Text(
                  '$count / $goal 회 인증',
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
