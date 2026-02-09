import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../crew/presentation/providers/crew_provider.dart';
import '../../data/exercise_type_repository.dart';
import '../../data/models/exercise_type.dart';

final exerciseTypeRepositoryProvider = Provider<ExerciseTypeRepository>((ref) {
  return ExerciseTypeRepository();
});

final exerciseTypesStreamProvider = StreamProvider<List<ExerciseType>>((ref) {
  final crewId = ref.watch(currentCrewIdProvider);
  final repo = ref.watch(exerciseTypeRepositoryProvider);
  return repo.watchExerciseTypes(crewId);
});

class ExerciseTypeNotifier extends AsyncNotifier<List<ExerciseType>> {
  @override
  Future<List<ExerciseType>> build() async {
    final crewId = ref.watch(currentCrewIdProvider);
    final repo = ref.watch(exerciseTypeRepositoryProvider);
    return await repo.getExerciseTypes(crewId);
  }

  Future<void> addExerciseType(String name) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(exerciseTypeRepositoryProvider);

    final type = ExerciseType(
      id: '',
      name: name,
      createdAt: DateTime.now(),
    );

    await repo.createExerciseType(crewId, type);
    ref.invalidateSelf();
  }

  Future<void> updateExerciseType(String typeId, String name) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(exerciseTypeRepositoryProvider);
    await repo.updateExerciseType(crewId, typeId, name);
    ref.invalidateSelf();
  }

  Future<void> deleteExerciseType(String typeId) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(exerciseTypeRepositoryProvider);
    await repo.deleteExerciseType(crewId, typeId);
    ref.invalidateSelf();
  }
}

final exerciseTypeNotifierProvider =
    AsyncNotifierProvider<ExerciseTypeNotifier, List<ExerciseType>>(
        () => ExerciseTypeNotifier());
