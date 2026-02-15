import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/router/router.dart';
import '../../../../core/models/member.dart';
import '../../../../core/widgets/shared_widgets.dart';
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
          return const EmptyState(
            icon: Icons.group_off,
            message: '멤버가 없습니다',
          );
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
                      const MeBadge(),
                    ],
                  ],
                ),
                subtitle: RoleBadge(role: member.role),
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

  void _showMemberActions(BuildContext context, WidgetRef ref, Member member) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(member.role == MemberRole.admin
                  ? '운영진 해제'
                  : '운영진으로 지정'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final repo = ref.read(manageMemberRepositoryProvider);
                final newRole = member.role == MemberRole.admin
                    ? MemberRole.member
                    : MemberRole.admin;
                await repo.updateMemberRole(crewId, member.uid, newRole);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Theme.of(sheetContext).colorScheme.error),
              title: Text(
                '추방하기',
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('멤버 추방'),
                    content: Text(
                      '${member.displayName}님을 정말 추방하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                          foregroundColor: Theme.of(ctx).colorScheme.onError,
                        ),
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
