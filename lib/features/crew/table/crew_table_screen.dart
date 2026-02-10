import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_keys.dart';
import 'table_provider.dart';
import 'workout_detail_dialog.dart';

class CrewTableScreen extends ConsumerWidget {
  final String crewId;

  const CrewTableScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(crewMembersProvider(crewId));
    final workoutsAsync = ref.watch(selectedWeekWorkoutsProvider(crewId));
    final weekOffset = ref.watch(selectedWeekOffsetProvider);

    final selectedDate = today().add(Duration(days: weekOffset * 7));
    final weekDates = getWeekDates(selectedDate);
    final weekStart = weekDates.first;
    final weekEnd = weekDates.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('크루 주간표'),
      ),
      body: Column(
        children: [
          // Week selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    ref.read(selectedWeekOffsetProvider.notifier).decrement();
                  },
                ),
                Text(
                  '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: weekOffset >= 0
                      ? null
                      : () {
                          ref.read(selectedWeekOffsetProvider.notifier).increment();
                        },
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (members) => workoutsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (workouts) {
                  // Create workout map: uid -> Set<dateKey>
                  final workoutMap = <String, Map<String, dynamic>>{};
                  for (final w in workouts) {
                    workoutMap['${w.uid}_${w.dateKey}'] = {
                      'workout': w,
                    };
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: _buildTable(
                        context,
                        members,
                        weekDates,
                        workoutMap,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    List members,
    List<DateTime> weekDates,
    Map<String, Map<String, dynamic>> workoutMap,
  ) {
    return DataTable(
      columnSpacing: 16,
      columns: [
        const DataColumn(
          label: Text('멤버', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...weekDates.map((date) {
          final dayName = DateFormat.E('ko').format(date);
          final dayNum = date.day.toString();
          return DataColumn(
            label: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayName, style: const TextStyle(fontSize: 12)),
                Text(dayNum, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
        const DataColumn(
          label: Text('합계', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
      rows: members.map((member) {
        int totalCount = 0;

        final cells = weekDates.map((date) {
          final dateKey = toDateKey(date);
          final key = '${member.uid}_$dateKey';
          final hasWorkout = workoutMap.containsKey(key);

          if (hasWorkout) totalCount++;

          return DataCell(
            Center(
              child: hasWorkout
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    )
                  : Icon(
                      Icons.circle_outlined,
                      color: Theme.of(context).colorScheme.outline,
                      size: 24,
                    ),
            ),
            onTap: hasWorkout
                ? () {
                    final workout = workoutMap[key]!['workout'];
                    showDialog(
                      context: context,
                      builder: (_) => WorkoutDetailDialog(workout: workout),
                    );
                  }
                : null,
          );
        }).toList();

        return DataRow(
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: member.photoUrl != null
                        ? NetworkImage(member.photoUrl!)
                        : null,
                    child: member.photoUrl == null
                        ? Text(
                            member.displayName.isNotEmpty
                                ? member.displayName[0]
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    member.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ...cells,
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: totalCount >= 3
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount/3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: totalCount >= 3
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
