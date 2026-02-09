import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../../../../core/utils/date_utils.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsNotifierProvider);
    final notifier = ref.read(statsNotifierProvider.notifier);
    final isWeekly = notifier.isWeekly;

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('주간')),
                ButtonSegment(value: false, label: Text('월간')),
              ],
              selected: {isWeekly},
              onSelectionChanged: (selection) {
                notifier.setWeekly(selection.first);
              },
            ),
          ),

          Expanded(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (stats) => _buildStatsContent(context, stats),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, StatsData stats) {
    final dateRange =
        '${AppDateUtils.toDisplayString(stats.startDate)} ~ ${AppDateUtils.toDisplayString(stats.endDate)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          dateRange,
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
                value: '${stats.totalLogs}회',
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
        const SizedBox(height: 24),

        // Members ranking
        _SectionTitle(title: '멤버별 인증'),
        if (stats.logsByMember.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('데이터 없음'),
          )
        else
          ...stats.logsByMember.entries.map((e) => _RankingTile(
                rank: stats.logsByMember.keys.toList().indexOf(e.key) + 1,
                label: e.key,
                value: '${e.value}회',
              )),
        const SizedBox(height: 24),

        // Exercise type ranking
        _SectionTitle(title: '운동 종류별'),
        if (stats.logsByExerciseType.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('데이터 없음'),
          )
        else
          ...stats.logsByExerciseType.entries.map((e) => _RankingTile(
                rank: stats.logsByExerciseType.keys.toList().indexOf(e.key) + 1,
                label: e.key,
                value: '${e.value}회',
              )),
      ],
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final String label;
  final String value;

  const _RankingTile({
    required this.rank,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final colors = [Colors.amber, Colors.grey, Colors.brown];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isTop3 ? colors[rank - 1].withAlpha(51) : null,
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
            color: isTop3 ? colors[rank - 1].shade700 : null,
          ),
        ),
      ),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
