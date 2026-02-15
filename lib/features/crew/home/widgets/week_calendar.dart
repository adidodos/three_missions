import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/date_keys.dart';
import '../../../../core/utils/mission_status.dart';
import '../crew_home_provider.dart';

class WeekCalendar extends ConsumerWidget {
  final String crewId;

  const WeekCalendar({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(myWeekWorkoutsProvider(crewId));
    final weekDates = getWeekDates(today());
    final todayDateKey = todayKey();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주간 캘린더',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            workoutsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('오류: $e'),
              data: (workouts) {
                final workoutDates = workouts.map((w) => w.dateKey).toSet();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDates.map((date) {
                    final dateKey = toDateKey(date);
                    final hasWorkout = workoutDates.contains(dateKey);
                    final isToday = dateKey == todayDateKey;
                    final status = getMissionStatus(
                      date: date,
                      hasRecord: hasWorkout,
                    );
                    final dayName = DateFormat.E('ko').format(date);

                    return _DayCell(
                      dayName: dayName,
                      date: date.day.toString(),
                      status: status,
                      isToday: isToday,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String dayName;
  final String date;
  final MissionStatus status;
  final bool isToday;

  const _DayCell({
    required this.dayName,
    required this.date,
    required this.status,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: status == MissionStatus.completed
                ? colorScheme.primaryContainer
                : isToday
                    ? colorScheme.surfaceContainerHighest
                    : null,
            border: isToday && status != MissionStatus.completed
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: switch (status) {
              MissionStatus.completed => Icon(
                  Icons.check,
                  color: colorScheme.primary,
                  size: 20,
                ),
              MissionStatus.missed => Icon(
                  Icons.close,
                  color: colorScheme.error,
                  size: 20,
                ),
              MissionStatus.none => Text(
                  date,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            },
          ),
        ),
      ],
    );
  }
}
