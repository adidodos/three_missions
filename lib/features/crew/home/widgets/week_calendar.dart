import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/workout.dart';
import '../../../../core/utils/date_keys.dart';
import '../../../../core/utils/mission_status.dart';
import '../../table/workout_detail_dialog.dart';
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
                final workoutMap = {
                  for (final w in workouts) w.dateKey: w,
                };

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekDates.map((date) {
                    final dateKey = toDateKey(date);
                    final workout = workoutMap[dateKey];
                    final isToday = dateKey == todayDateKey;
                    final status = getMissionStatus(
                      date: date,
                      hasRecord: workout != null,
                    );
                    final dayName = DateFormat.E('ko').format(date);

                    return _DayCell(
                      dayName: dayName,
                      date: date.day.toString(),
                      status: status,
                      isToday: isToday,
                      workout: workout,
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
  final Workout? workout;

  const _DayCell({
    required this.dayName,
    required this.date,
    required this.status,
    required this.isToday,
    this.workout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final cell = Column(
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

    if (status == MissionStatus.completed && workout != null) {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => WorkoutDetailDialog(workout: workout!),
          );
        },
        child: cell,
      );
    }

    return cell;
  }
}
