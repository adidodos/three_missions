import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/join_request.dart';
import '../../../core/models/member.dart';
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
      body: Column(
        children: [
          Padding(
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

          Expanded(
            child: searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (crews) {
                if (_query.isEmpty) {
                  return const Center(
                    child: Text('크루 이름을 검색하세요'),
                  );
                }

                if (crews.isEmpty) {
                  return const Center(
                    child: Text('검색 결과가 없습니다'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: crews.length,
                  itemBuilder: (context, index) {
                    final crew = crews[index];
                    return _CrewSearchItem(crewId: crew.id, crewName: crew.name);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewSearchItem extends ConsumerWidget {
  final String crewId;
  final String crewName;

  const _CrewSearchItem({
    required this.crewId,
    required this.crewName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(myMembershipProvider(crewId));
    final requestAsync = ref.watch(myRequestProvider(crewId));

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.group),
        ),
        title: Text(crewName),
        trailing: memberAsync.when(
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error),
          data: (member) {
            if (member != null && member.status == MemberStatus.active) {
              return Chip(
                label: const Text('크루원'),
                backgroundColor: Colors.blue.shade100,
              );
            }

            return requestAsync.when(
              loading: () => const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Icon(Icons.error),
              data: (request) {
                if (request == null) {
                  return ElevatedButton(
                    onPressed: () => _requestJoin(context, ref),
                    child: const Text('가입 신청'),
                  );
                }

                switch (request.status) {
                  case RequestStatus.pending:
                    return Chip(
                      label: const Text('대기중'),
                      backgroundColor: Colors.orange.shade100,
                    );
                  case RequestStatus.approved:
                    return Chip(
                      label: const Text('승인됨'),
                      backgroundColor: Colors.green.shade100,
                    );
                  case RequestStatus.rejected:
                    return Chip(
                      label: const Text('거절됨'),
                      backgroundColor: Colors.red.shade100,
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _requestJoin(BuildContext context, WidgetRef ref) async {
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
      await repo.createRequest(crewId, request);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가입 신청이 완료되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}
