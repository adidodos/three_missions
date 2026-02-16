import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/theme_provider.dart';
import 'edit_profile_dialog.dart';
import 'delete_account_dialog.dart';

final _appInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appInfoAsync = ref.watch(_appInfoProvider);
    final isAdminAsync = ref.watch(isAdminProvider);
    final canShowDeveloperMenus =
        kDebugMode ||
        isAdminAsync.maybeWhen(data: (isAdmin) => isAdmin, orElse: () => false);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // --- 알림 ---
          _SectionHeader(title: '알림'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('푸시 알림'),
            subtitle: const Text('미션 리마인더 및 크루 활동 알림'),
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.setBool('notifications_enabled', value);
            },
          ),

          const Divider(),

          // --- 계정 ---
          _SectionHeader(title: '계정'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필 수정'),
            subtitle: Text(user?.displayName ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEditProfileDialog(context, user),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '회원 탈퇴',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showDeleteAccountDialog(context, user),
          ),

          const Divider(),

          // --- 화면 ---
          _SectionHeader(title: '화면'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('테마 설정'),
            subtitle: Text(_themeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, themeMode),
          ),

          const Divider(),

          // --- 정보 ---
          _SectionHeader(title: '정보'),
          ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: const Text('문의하기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/inquiry'),
          ),
          isAdminAsync.when(
            data: (isAdmin) => isAdmin
                ? ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('문의 관리'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/inquiry/admin'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (canShowDeveloperMenus)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('오픈소스 라이선스'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Three Missions',
              ),
            ),
          appInfoAsync.when(
            data: (info) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 버전'),
              subtitle: Text('v${info.version} (${info.buildNumber})'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('앱 버전'),
              subtitle: Text('...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '시스템 설정',
      ThemeMode.light => '라이트 모드',
      ThemeMode.dark => '다크 모드',
    };
  }

  void _showThemeDialog(BuildContext context, ThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('테마 설정'),
        children: ThemeMode.values.map((mode) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(
                  mode == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == current
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(_themeModeLabel(mode)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, User? user) {
    if (user == null) return;
    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(user: user),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, User? user) {
    if (user == null) return;
    showDialog(
      context: context,
      builder: (_) => DeleteAccountDialog(user: user),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
