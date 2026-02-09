import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/log_provider.dart';
import '../../data/models/workout_log.dart';
import '../../../../core/utils/date_utils.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('기록이 없습니다'));
          }

          // Group by date
          final groupedLogs = <String, List<WorkoutLog>>{};
          for (final log in logs) {
            groupedLogs.putIfAbsent(log.date, () => []).add(log);
          }

          final dates = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final dateLogs = groupedLogs[date]!;
              final dateTime = AppDateUtils.fromDateString(date);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      AppDateUtils.toDisplayString(dateTime),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...dateLogs.map((log) => Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(log.memberName.isNotEmpty
                                ? log.memberName[0]
                                : '?'),
                          ),
                          title: Text(log.exerciseTypeName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.memberName),
                              if (log.memo != null && log.memo!.isNotEmpty)
                                Text(
                                  log.memo!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          trailing: log.durationMinutes != null
                              ? Text('${log.durationMinutes}분')
                              : null,
                          isThreeLine:
                              log.memo != null && log.memo!.isNotEmpty,
                          onTap: () => context.push('/logs/edit/${log.id}'),
                        ),
                      )),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/logs/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
