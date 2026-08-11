import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/theme_mode_provider.dart';
import '../auth/auth_colors.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ThemeOption(
              title: 'Light',
              subtitle: 'Always use light mode',
              icon: Icons.light_mode_outlined,
              selected: currentMode == ThemeMode.light,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Always use dark mode',
              icon: Icons.dark_mode_outlined,
              selected: currentMode == ThemeMode.dark,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(height: 12),
            _ThemeOption(
              title: 'System',
              subtitle: 'Match your device setting',
              icon: Icons.brightness_auto_outlined,
              selected: currentMode == ThemeMode.system,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AuthColors.primary : Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? AuthColors.primary : Colors.black54),
        title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: selected ? const Icon(Icons.check_circle, color: AuthColors.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
