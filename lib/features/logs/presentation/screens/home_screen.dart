import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/log_provider.dart';
import '../../../../core/utils/date_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayLogsAsync = ref.watch(todayLogsStreamProvider);
    final today = AppDateUtils.today();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Three Missions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppDateUtils.toDisplayString(today),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: todayLogsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (logs) => logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '오늘 운동 기록이 없습니다',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+ 버튼을 눌러 인증하세요!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(log.memberName.isNotEmpty
                                  ? log.memberName[0]
                                  : '?'),
                            ),
                            title: Text(log.exerciseTypeName),
                            subtitle: Text(log.memberName),
                            trailing: log.durationMinutes != null
                                ? Text('${log.durationMinutes}분')
                                : null,
                            onTap: () => context.push('/logs/edit/${log.id}'),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/logs/add'),
        icon: const Icon(Icons.add),
        label: const Text('인증하기'),
      ),
    );
  }
}
