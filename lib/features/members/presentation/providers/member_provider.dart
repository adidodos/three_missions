import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../crew/presentation/providers/crew_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/member_repository.dart';
import '../../data/models/member.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});

final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  final crewId = ref.watch(currentCrewIdProvider);
  final repo = ref.watch(memberRepositoryProvider);
  return repo.watchMembers(crewId);
});

final myMemberProvider = FutureProvider<Member?>((ref) async {
  final crewId = ref.watch(currentCrewIdProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(memberRepositoryProvider);
  return await repo.getMyMember(crewId, user.uid);
});

class MemberNotifier extends AsyncNotifier<List<Member>> {
  @override
  Future<List<Member>> build() async {
    final crewId = ref.watch(currentCrewIdProvider);
    final repo = ref.watch(memberRepositoryProvider);
    return await repo.getMembers(crewId);
  }

  Future<void> addMember(String name) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(memberRepositoryProvider);

    final member = Member(
      id: '',
      name: name,
      isMe: false,
      createdAt: DateTime.now(),
    );

    await repo.createMember(crewId, member);
    ref.invalidateSelf();
  }

  Future<void> updateMember(String memberId, String name) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(memberRepositoryProvider);
    await repo.updateMember(crewId, memberId, name);
    ref.invalidateSelf();
  }

  Future<void> deleteMember(String memberId) async {
    final crewId = ref.read(currentCrewIdProvider);
    final repo = ref.read(memberRepositoryProvider);
    await repo.deleteMember(crewId, memberId);
    ref.invalidateSelf();
  }
}

final memberNotifierProvider =
    AsyncNotifierProvider<MemberNotifier, List<Member>>(() => MemberNotifier());
