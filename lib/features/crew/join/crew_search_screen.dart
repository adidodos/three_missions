import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/join_request.dart';
import '../../../core/models/member.dart';
import '../../hub/hub_provider.dart';
import '../../wall/widgets/wall_section.dart';
import 'join_provider.dart';

class CrewSearchScreen extends ConsumerStatefulWidget {
  const CrewSearchScreen({super.key});

  @override
  ConsumerState<CrewSearchScreen> createState() => _CrewSearchScreenState();
}

class _CrewSearchScreenState extends ConsumerState<CrewSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _query = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(crewSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('크루 검색'),
      ),
      body: CustomScrollView(
        slivers: [
          // ── 검색바 ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '크루 이름으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
          ),

          // ── 검색 결과 ────────────────────────────────────────────────────────
          if (_query.isNotEmpty)
            searchAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('오류: $e'),
                ),
              ),
              data: (crews) {
                if (crews.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('검색 결과가 없습니다')),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CrewSearchItem(
                          crewId: crews[index].id,
                          crewName: crews[index].name,
                        ),
                      ),
                      childCount: crews.length,
                    ),
                  ),
                );
              },
            )
          else
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text('크루 이름을 검색하세요',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
            ),

          // ── 구분선 ──────────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: Divider(height: 1)),

          // ── 담벼락 섹션 ──────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: WallSection()),
        ],
      ),
    );
  }
}

class _CrewSearchItem extends ConsumerWidget {
  final String crewId;
  final String crewName;

  const _CrewSearchItem({required this.crewId, required this.crewName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(myMembershipProvider(crewId));
    final requestAsync = ref.watch(myRequestProvider(crewId));

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.group)),
        title: Text(crewName),
        trailing: memberAsync.when(
          loading: () => const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => const Icon(Icons.error),
          data: (member) {
            if (member != null && member.status == MemberStatus.active) {
              return Chip(
                label: const Text('크루원'),
                backgroundColor: Colors.blue.shade100,
              );
            }
            if (member != null && member.status == MemberStatus.banned) {
              return ElevatedButton(
                onPressed: () => _reapplyAfterBan(context, ref),
                child: const Text('재신청'),
              );
            }
            return requestAsync.when(
              loading: () => const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Icon(Icons.error),
              data: (request) {
                if (request == null) {
                  return ElevatedButton(
                    onPressed: () => _requestJoin(context, ref),
                    child: const Text('크루 신청'),
                  );
                }
                switch (request.status) {
                  case RequestStatus.pending:
                    return Chip(
                        label: const Text('승인요청 대기'),
                        backgroundColor: Colors.orange.shade100);
                  case RequestStatus.approved:
                    return Chip(
                        label: const Text('크루원'),
                        backgroundColor: Colors.green.shade100);
                  case RequestStatus.rejected:
                    return ElevatedButton(
                      onPressed: () =>
                          _requestJoin(context, ref, isReapply: true),
                      child: const Text('재요청'),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _reapplyAfterBan(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final memberRepo = ref.read(joinMemberRepositoryProvider);
      await memberRepo.removeMember(crewId, user.uid);
      final joinRepo = ref.read(joinRequestRepositoryProvider);
      final request = JoinRequest(
        uid: user.uid,
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );
      await joinRepo.reapplyRequest(crewId, request);
      ref.invalidate(myMembershipProvider(crewId));
      ref.invalidate(myRequestProvider(crewId));
      ref.invalidate(myJoinRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('재신청이 완료되었습니다')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Future<void> _requestJoin(BuildContext context, WidgetRef ref,
      {bool isReapply = false}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final repo = ref.read(joinRequestRepositoryProvider);
      final request = JoinRequest(
        uid: user.uid,
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      );
      if (isReapply) {
        await repo.reapplyRequest(crewId, request);
      } else {
        await repo.createRequest(crewId, request);
      }
      ref.invalidate(myJoinRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('가입 신청이 완료되었습니다')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }
}
