import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../crew/presentation/providers/crew_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/log_repository.dart';
import '../../data/models/workout_log.dart';
import '../../../../core/utils/date_utils.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

final logsStreamProvider = StreamProvider<List<WorkoutLog>>((ref) {
  final crewId = ref.watch(currentCrewIdProvider);
  final repo = ref.watch(logRepositoryProvider);
  return repo.watchLogs(crewId);
});

final todayLogsStreamProvider = StreamProvider<List<WorkoutLog>>((ref) {
  final crewId = ref.watch(currentCrewIdProvider);
  final repo = ref.watch(logRepositoryProvider);
  final today = AppDateUtils.toDateString(AppDateUtils.today());
  return repo.watchLogsByDate(crewId, today);
});

class LogNotifier extends AsyncNotifier<List<WorkoutLog>> {
  @override
  Future<List<WorkoutLog>> build() async {
    final crewId = ref.watch(currentCrewIdProvider);
    final repo = ref.watch(logRepositoryProvider);
    return await repo.getLogs(crewId);
  }

  Future<void> addLog({
    required String memberId,
    required String memberName,
    required String exerciseTypeId,
    required String exerciseTypeName,
    required String date,
    String? memo,
    int? durationMinutes,
  }) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(logRepositoryProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) return;

    final log = WorkoutLog(
      id: '',
      memberId: memberId,
      memberName: memberName,
      exerciseTypeId: exerciseTypeId,
      exerciseTypeName: exerciseTypeName,
      date: date,
      memo: memo,
      durationMinutes: durationMinutes,
      createdByUid: user.uid,
      createdAt: DateTime.now(),
    );

    await repo.createLog(crewId, log);
    ref.invalidateSelf();
  }

  Future<void> updateLog(WorkoutLog log) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(logRepositoryProvider);
    await repo.updateLog(crewId, log);
    ref.invalidateSelf();
  }

  Future<void> deleteLog(String logId) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(logRepositoryProvider);
    await repo.deleteLog(crewId, logId);
    ref.invalidateSelf();
  }
}

final logNotifierProvider =
    AsyncNotifierProvider<LogNotifier, List<WorkoutLog>>(() => LogNotifier());
