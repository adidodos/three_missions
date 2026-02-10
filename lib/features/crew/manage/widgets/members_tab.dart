import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/router/router.dart';
import '../../../../core/models/member.dart';
import '../manage_provider.dart';

class MembersTab extends ConsumerWidget {
  final String crewId;

  const MembersTab({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(manageMembersProvider(crewId));
    final currentMember = ref.watch(crewMembershipProvider(crewId)).value;
    final currentUser = ref.watch(currentUserProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('멤버가 없습니다'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isMe = member.uid == currentUser?.uid;
            final canManage = currentMember?.role == MemberRole.owner &&
                member.role != MemberRole.owner;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: member.photoUrl != null
                      ? NetworkImage(member.photoUrl!)
                      : null,
                  child: member.photoUrl == null
                      ? Text(member.displayName.isNotEmpty
                          ? member.displayName[0]
                          : '?')
                      : null,
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(member.displayName)),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '나',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(_roleLabel(member.role)),
                trailing: canManage
                    ? IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showMemberActions(context, ref, member),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  String _roleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return '크루장';
      case MemberRole.admin:
        return '운영진';
      case MemberRole.member:
        return '멤버';
    }
  }

  void _showMemberActions(BuildContext context, WidgetRef ref, Member member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(member.role == MemberRole.admin
                  ? '운영진 해제'
                  : '운영진으로 지정'),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(manageMemberRepositoryProvider);
                final newRole = member.role == MemberRole.admin
                    ? MemberRole.member
                    : MemberRole.admin;
                await repo.updateMemberRole(crewId, member.uid, newRole);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
              title: Text(
                '추방하기',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('멤버 추방'),
                    content: Text('${member.displayName}님을 추방하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('추방'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final repo = ref.read(manageMemberRepositoryProvider);
                  await repo.banMember(crewId, member.uid);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
