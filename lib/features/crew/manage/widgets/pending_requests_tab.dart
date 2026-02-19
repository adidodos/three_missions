import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/models/member.dart';
import '../../../../core/models/join_request.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../manage_provider.dart';

class PendingRequestsTab extends ConsumerWidget {
  final String crewId;

  const PendingRequestsTab({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(managePendingRequestsProvider(crewId));

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox,
            message: '대기 중인 가입 신청이 없습니다',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _RequestCard(crewId: crewId, request: request);
          },
        );
      },
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final String crewId;
  final JoinRequest request;

  const _RequestCard({required this.crewId, required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isLoading = false;

  Future<void> _approve() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      // Read all providers before async gaps — the widget may be
      // removed from the tree once the request status changes, which
      // would invalidate ref.
      final requestRepo = ref.read(manageRequestRepositoryProvider);
      final memberRepo = ref.read(manageMemberRepositoryProvider);

      final member = Member(
        uid: widget.request.uid,
        displayName: widget.request.displayName,
        photoUrl: widget.request.photoUrl,
        role: MemberRole.member,
        joinedAt: DateTime.now(),
      );

      // Add as member first, then approve request.
      // This way, if addMember fails the request stays pending and can
      // be retried.  If we approved first, the card disappears and the
      // member is never created.
      await memberRepo.addMember(widget.crewId, member);
      await requestRepo.approveRequest(widget.crewId, widget.request.uid, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.request.displayName}님을 승인했습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 처리 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가입 거절'),
        content: Text('${widget.request.displayName}님의 가입을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repo = ref.read(manageRequestRepositoryProvider);
      await repo.rejectRequest(widget.crewId, widget.request.uid, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.request.displayName}님의 가입을 거절했습니다')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  photoUrl: widget.request.photoUrl,
                  // join-request photoUrl is only set from existing custom photo
                  hasCustomPhoto: widget.request.photoUrl != null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('M월 d일 신청').format(widget.request.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _reject,
                    child: const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _approve,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('승인'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
