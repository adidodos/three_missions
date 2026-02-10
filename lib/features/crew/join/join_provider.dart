import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/repositories/join_request_repository.dart';
import '../../../core/models/crew.dart';
import '../../../core/models/join_request.dart';
import '../../../core/auth/auth_provider.dart';

final joinCrewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return JoinRequestRepository();
});

final crewSearchProvider = FutureProvider.family<List<Crew>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(joinCrewRepositoryProvider);
  try {
    return await repo.searchCrews(query);
  } catch (_) {
    return [];
  }
});

final myRequestProvider = StreamProvider.family<JoinRequest?, String>((ref, crewId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final repo = ref.read(joinRequestRepositoryProvider);
  return repo.watchMyRequest(crewId, user.uid);
});
