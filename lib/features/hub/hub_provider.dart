import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/repositories/crew_repository.dart';
import '../../core/repositories/join_request_repository.dart';
import '../../core/models/crew.dart';
import '../../core/models/join_request.dart';

final crewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final hubJoinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return JoinRequestRepository();
});

final myCrewsProvider = StreamProvider<List<Crew>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.read(crewRepositoryProvider);
  return repo.watchMyCrews(user.uid);
});

/// Join requests the current user has sent (pending + rejected), with crew info.
final myJoinRequestsProvider = FutureProvider<List<({JoinRequest request, Crew crew})>>((ref) async {
  // Re-fetch when crew list changes (e.g. after join approval)
  ref.watch(myCrewsProvider);

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final joinRepo = ref.read(hubJoinRequestRepositoryProvider);
  final crewRepo = ref.read(crewRepositoryProvider);

  final requests = await joinRepo.getMyJoinRequests(user.uid);
  final results = <({JoinRequest request, Crew crew})>[];

  for (final item in requests) {
    final crew = await crewRepo.getCrew(item.crewId);
    if (crew != null) {
      results.add((request: item.request, crew: crew));
    }
  }

  return results;
});
