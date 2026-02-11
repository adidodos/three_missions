import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/member.dart';
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
            return const Center(child: Text('멤버가 없습니다'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member.uid == currentUser?.uid;

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
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '나',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(_roleLabel(member.role)),
                ),
              );
            },
          );
        },
      ),
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
}
