import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_keys.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  final String crewId;

  const StatsScreen({super.key, required this.crewId});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _WeeklyTab(crewId: widget.crewId),
          _MonthlyTab(crewId: widget.crewId),
        ],
      ),
    );
  }
}

class _WeeklyTab extends ConsumerWidget {
  final String crewId;

  const _WeeklyTab({required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myWeeklyStatsProvider(crewId));
    final weekDates = getWeekDates(today());

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Week range
            Text(
              '${DateFormat('M월 d일').format(weekDates.first)} - ${DateFormat('M월 d일').format(weekDates.last)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '이번 주 인증',
                    value: '${stats.count}회',
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: '연속 인증',
                    value: '${stats.streak}일',
                    icon: Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mission status
            Card(
              color: stats.isSuccess
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      stats.isSuccess ? Icons.emoji_events : Icons.flag,
                      size: 48,
                      color:
                          stats.isSuccess ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stats.isSuccess ? '미션 성공!' : '미션 진행중',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: stats.isSuccess
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.isSuccess
                          ? '이번 주 3회 인증을 달성했어요!'
                          : '${3 - stats.count}회 더 인증하면 미션 성공!',
                      style: TextStyle(
                        color: stats.isSuccess
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행률',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (stats.count / 3).clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text('${stats.count} / 3 회'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthlyTab extends ConsumerWidget {
  final String crewId;

  const _MonthlyTab({required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myMonthlyStatsProvider(crewId));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Month
            Text(
              DateFormat('yyyy년 M월').format(today()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '총 인증',
                    value: '${stats.totalCount}회',
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: '미션 성공',
                    value: '${stats.successfulWeeks}주',
                    icon: Icons.emoji_events,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type distribution
            if (stats.typeDistribution.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '운동 종류별',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...stats.typeDistribution.entries
                          .toList()
                          .map((entry) {
                        final percent = (entry.value / stats.totalCount * 100)
                            .toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text('${entry.value}회 ($percent%)'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
