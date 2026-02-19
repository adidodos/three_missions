import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/member.dart';

/// 프로필 아바타.
///
/// [hasCustomPhoto]가 true일 때만 [photoUrl]을 표시하고,
/// 그 외에는 역도 기본 아이콘(🏋️)을 보여준다.
/// Google photoURL은 절대 사용하지 않는 정책 – [hasCustomPhoto] 게이트로 보장.
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  /// true = 사용자가 직접 업로드한 커스텀 사진 존재.
  /// false (기본값) = 기본 아바타(역도 아이콘) 표시.
  final bool hasCustomPhoto;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.hasCustomPhoto = false,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (hasCustomPhoto && photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    // 기본 아바타: 역도(fitness_center) 아이콘
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.fitness_center, size: radius),
    );
  }
}

/// 역할 문자열 반환.
String roleLabel(MemberRole role) => switch (role) {
      MemberRole.owner => '크루장',
      MemberRole.admin => '운영진',
      MemberRole.member => '멤버',
    };

/// 역할별 색상 배지.
class RoleBadge extends StatelessWidget {
  final MemberRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg, String label) = switch (role) {
      MemberRole.owner => (
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
          '크루장',
        ),
      MemberRole.admin => (
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
          '운영진',
        ),
      MemberRole.member => (
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
          '멤버',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "나" 배지.
class MeBadge extends StatelessWidget {
  const MeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '나',
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// 빈 상태 위젯 (아이콘 + 메시지).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? submessage;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.submessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: colorScheme.outline),
          ),
          if (submessage != null) ...[
            const SizedBox(height: 8),
            Text(
              submessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
