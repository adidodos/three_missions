import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/join_request.dart';
import '../../core/repositories/storage_repository.dart';
import '../../core/router/router.dart';
import '../crew/home/workout_form_screen.dart';
import '../../core/widgets/shared_widgets.dart';
import 'hub_provider.dart';
import 'create_crew_dialog.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final crewsAsync = ref.watch(myCrewsProvider);
    final joinRequestsAsync = ref.watch(myJoinRequestsProvider);
    final userProfile = ref.watch(userProfileProvider).value;

    // Ensure user profile exists
    ref.watch(ensureUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Three Missions'),
        actions: [
          IconButton(
            icon: ProfileAvatar(
              photoUrl: userProfile?.photoUrl,
              hasCustomPhoto: userProfile?.hasCustomPhoto ?? false,
              radius: 16,
            ),
            onPressed: () => _showProfileBottomSheet(context, ref, user, userProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCrewsProvider);
          ref.invalidate(myJoinRequestsProvider);
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

            // Join requests section
            joinRequestsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      '가입 요청',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (requests.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              '가입신청한 크루 없음',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...requests.map((item) {
                      final isPending = item.request.status == RequestStatus.pending;
                      final isRejected = item.request.status == RequestStatus.rejected;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRejected
                                ? Theme.of(context).colorScheme.errorContainer
                                : null,
                            child: Icon(
                              isPending ? Icons.hourglass_top : Icons.block,
                              color: isRejected
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                          title: Text(item.crew.name),
                          subtitle: Text(
                            isPending ? '승인 대기 중' : '거절됨',
                            style: TextStyle(
                              color: isRejected
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                          trailing: isRejected
                              ? TextButton(
                                  onPressed: () => _reapplyJoinRequest(context, ref, item.crew.id, item.request),
                                  child: const Text('재가입'),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context, WidgetRef ref, User? user, UserProfile? userProfile) {
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
                        ProfileAvatar(
                          photoUrl: userProfile?.photoUrl,
                          hasCustomPhoto: userProfile?.hasCustomPhoto ?? false,
                          radius: 24,
                        ),
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
                context.push('/settings');
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
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!context.mounted) return;

    // Read providers before showing dialog (widget stays mounted)
    final storageRepo = ref.read(storageRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);
    final memberRepo = ref.read(memberRepositoryProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final file = File(picked.path);
      final url = await storageRepo.uploadProfilePhoto(user.uid, file);

      await authRepo.updatePhotoURL(url);
      await userRepo.updatePhotoUrl(user.uid, url);
      await memberRepo.updatePhotoUrlInAllCrews(user.uid, url);

    } on UploadException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage)),
        );
      }
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

  Future<void> _reapplyJoinRequest(BuildContext context, WidgetRef ref, String crewId, JoinRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재가입 요청'),
        content: const Text('이 크루에 다시 가입 요청을 보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('요청'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final repo = ref.read(hubJoinRequestRepositoryProvider);
      await repo.reapplyRequest(crewId, request);
      ref.invalidate(myJoinRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('가입 요청을 다시 보냈습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: $e')),
        );
      }
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
