import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/router/router.dart';
import 'hub_provider.dart';
import 'create_crew_dialog.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final crewsAsync = ref.watch(myCrewsProvider);

    // Ensure user profile exists
    ref.watch(ensureUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Three Missions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCrewsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            user?.email ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCreateCrewDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('크루 생성'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/crew/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('크루 검색'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My crews
            Text(
              '내 크루',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            crewsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('오류: $e'),
                ),
              ),
              data: (crews) {
                if (crews.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.group_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '가입된 크루가 없습니다',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('크루를 생성하거나 검색해서 가입하세요!'),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: crews.map((crew) {
                    final memberAsync = ref.watch(crewMembershipProvider(crew.id));
                    final role = memberAsync.value?.role;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.group),
                        ),
                        title: Text(crew.name),
                        subtitle: role != null
                            ? Text(_roleLabel(role))
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/crew/${crew.id}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(dynamic role) {
    switch (role.toString()) {
      case 'MemberRole.owner':
        return '크루장';
      case 'MemberRole.admin':
        return '운영진';
      default:
        return '멤버';
    }
  }

  Future<void> _showCreateCrewDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateCrewDialog(),
    );

    if (result == true) {
      ref.invalidate(myCrewsProvider);
    }
  }
}
