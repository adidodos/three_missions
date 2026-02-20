import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/repositories/join_request_repository.dart';
import '../../../core/repositories/member_repository.dart';
import '../../../core/models/crew.dart';
import '../../../core/models/join_request.dart';
import '../../../core/models/member.dart';
import '../../../core/auth/auth_provider.dart';

final joinCrewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final joinRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return JoinRequestRepository();
});

final joinMemberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final crewSearchProvider = FutureProvider.family<List<Crew>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repo = ref.read(joinCrewRepositoryProvider);
  try {
    return await repo.searchCrews(query);
  } catch (e) {
    debugPrint('searchCrews error: $e');
    return [];
  }
});

final myMembershipProvider = FutureProvider.family<Member?, String>((ref, crewId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.read(joinMemberRepositoryProvider);
  try {
    return await repo.getMember(crewId, user.uid);
  } catch (e) {
    // Non-members get permission-denied when querying membership doc
    debugPrint('myMembershipProvider: $e');
    return null;
  }
});

final myRequestProvider = StreamProvider.family<JoinRequest?, String>((ref, crewId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  final repo = ref.read(joinRequestRepositoryProvider);
  return repo.watchMyRequest(crewId, user.uid);
});
