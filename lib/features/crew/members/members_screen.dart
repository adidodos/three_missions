import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../manage/manage_provider.dart';

class MembersScreen extends ConsumerWidget {
  final String crewId;

  const MembersScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(manageMembersProvider(crewId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('크루원 목록'),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const EmptyState(
              icon: Icons.group_off,
              message: '크루원이 없습니다',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member.uid == currentUser?.uid;

              return Card(
                child: ListTile(
                  leading: ProfileAvatar(photoUrl: member.photoUrl),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
