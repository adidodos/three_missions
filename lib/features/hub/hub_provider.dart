import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/repositories/crew_repository.dart';
import '../../core/models/crew.dart';

final crewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final myCrewsProvider = FutureProvider<List<Crew>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repo = ref.read(crewRepositoryProvider);
  return await repo.getMyCrews(user.uid);
});
