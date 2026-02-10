import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/join_request.dart';
import '../join/join_provider.dart';

class PendingScreen extends ConsumerWidget {
  final String crewId;

  const PendingScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final requestAsync = ref.watch(myRequestProvider(crewId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('가입 대기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/hub'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),

            requestAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('오류: $e', textAlign: TextAlign.center),
              data: (request) {
                if (request == null) {
                  return Column(
                    children: [
                      Text(
                        '이 크루에 가입되어 있지 않습니다',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _requestJoin(context, ref),
                        icon: const Icon(Icons.person_add),
                        label: const Text('가입 신청하기'),
                      ),
                    ],
                  );
                }

                String message;
                IconData icon;
                Color color;

                switch (request.status) {
                  case RequestStatus.pending:
                    message = '가입 신청이 승인 대기 중입니다';
                    icon = Icons.pending;
                    color = Colors.orange;
                    break;
                  case RequestStatus.approved:
                    message = '가입이 승인되었습니다!';
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case RequestStatus.rejected:
                    message = '가입 신청이 거절되었습니다';
                    icon = Icons.cancel;
                    color = Colors.red;
                    break;
                }

                return Column(
                  children: [
                    Icon(icon, size: 48, color: color),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // UID display
            if (user != null) ...[
              Text(
                '내 UID',
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.uid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UID가 복사되었습니다')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.uid,
                          style: const TextStyle(fontFamily: 'monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 16),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: () => context.go('/hub'),
              icon: const Icon(Icons.home),
              label: const Text('홈으로'),
            ),
          ],
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
