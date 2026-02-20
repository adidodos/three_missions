import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/crew_repository.dart';
import '../../../core/repositories/member_repository.dart';
import '../../../core/repositories/join_request_repository.dart';
import '../../../core/models/member.dart';
import '../../../core/models/join_request.dart';

final manageCrewRepositoryProvider = Provider<CrewRepository>((ref) {
  return CrewRepository();
});

final manageMemberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final manageRequestRepositoryProvider = Provider<JoinRequestRepository>((ref) {
  return JoinRequestRepository();
});

final manageMembersProvider = StreamProvider.family<List<Member>, String>((ref, crewId) {
  final repo = ref.read(manageMemberRepositoryProvider);
  return repo.watchMembers(crewId);
});

final managePendingRequestsProvider = StreamProvider.family<List<JoinRequest>, String>((ref, crewId) {
  final repo = ref.read(manageRequestRepositoryProvider);
  return repo.watchPendingRequests(crewId);
});
