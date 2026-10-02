import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/core/theme/theme_provider.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final displayName = user?.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? 'Utilisateur'
        : displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppPalette.primary,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              user?.email ?? '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: AppPalette.primary,
            ),
            title: const Text('Modifier le nom'),
            onTap: () => _editName(context, ref, displayName ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppPalette.primary),
            title: const Text('Changer le mot de passe'),
            onTap: () => _changePassword(context, ref),
          ),
          ListTile(
            leading: const Icon(
              Icons.dark_mode_outlined,
              color: AppPalette.primary,
            ),
            title: const Text('Thème'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _chooseTheme(context, ref, themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppPalette.error),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: AppPalette.error),
            ),
            onTap: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Clair',
      ThemeMode.dark => 'Sombre',
      ThemeMode.system => 'Système',
    };
  }

  static Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;
    await ref
        .read(authNotifierProvider.notifier)
        .changeDisplayName(displayName: name);
  }

  static Future<void> _changePassword(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (password == null || password.isEmpty) return;
    await ref
        .read(authNotifierProvider.notifier)
        .changePassword(newPassword: password);
  }

  static Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Thème'),
        children: ThemeMode.values
            .map(
              (mode) => ListTile(
                title: Text(_themeLabel(mode)),
                trailing: mode == currentMode
                    ? const Icon(Icons.check, color: AppPalette.primary)
                    : null,
                onTap: () => Navigator.pop(context, mode),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }
}
