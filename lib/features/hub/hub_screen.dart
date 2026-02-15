import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/repositories/member_repository.dart';
import '../../core/repositories/storage_repository.dart';
import '../../core/router/router.dart';
import '../../core/widgets/shared_widgets.dart';
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
            icon: ProfileAvatar(photoUrl: user?.photoURL, radius: 16),
            onPressed: () => _showProfileBottomSheet(context, ref, user),
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
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.group_off,
                        message: '가입된 크루가 없습니다',
                        submessage: '크루를 생성하거나 검색해서 가입하세요!',
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
                            ? RoleBadge(role: role)
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

  void _showProfileBottomSheet(BuildContext context, WidgetRef ref, User? user) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Account card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _changeProfilePhoto(context, ref, user);
                    },
                    child: Stack(
                      children: [
                        ProfileAvatar(photoUrl: user?.photoURL, radius: 24),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(sheetContext).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Theme.of(sheetContext).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Settings
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('설정'),
              onTap: () {
                Navigator.pop(sheetContext);
              },
            ),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authRepositoryProvider).signOut();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref, User? user) async {
    if (user == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final file = File(picked.path);
      final storageRepo = StorageRepository();
      final url = await storageRepo.uploadProfilePhoto(user.uid, file);

      if (url == null) throw Exception('업로드 실패');

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.updatePhotoURL(url);

      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.updatePhotoUrl(user.uid, url);

      final memberRepo = MemberRepository();
      await memberRepo.updatePhotoUrlInAllCrews(user.uid, url);

      ref.invalidate(authStateProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 사진 변경 실패: $e')),
        );
      }
    } finally {
      if (context.mounted) Navigator.pop(context);
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
