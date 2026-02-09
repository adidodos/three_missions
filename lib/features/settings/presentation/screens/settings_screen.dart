import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('멤버 관리'),
            subtitle: const Text('크루 멤버 추가/수정/삭제'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/members'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('운동 종류 관리'),
            subtitle: const Text('운동 종류 추가/수정/삭제'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/exercise-types'),
          ),
          const Divider(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Three Missions v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
