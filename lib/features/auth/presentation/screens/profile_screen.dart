import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/core/theme/theme_provider.dart';
import 'package:urban_resilience/features/auth/presentation/auth_error_message.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final displayName = user?.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? 'Utilisateur'
        : displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
              Center(
                child: Text(
                  isAdmin ? 'Compte administrateur' : 'Compte citoyen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 32),
              _ProfileTile(
                icon: Icons.person_outline,
                title: 'Modifier le nom',
                onTap: () => editDisplayName(context, ref, displayName ?? ''),
              ),
              _ProfileTile(
                icon: Icons.mail_outline,
                title: 'Adresse e-mail',
                subtitle: user?.email ?? '',
                onTap: null,
              ),
              _ProfileTile(
                icon: Icons.lock_outline,
                title: 'Changer le mot de passe',
                onTap: () => changePassword(context, ref),
              ),
              _ProfileTile(
                icon: Icons.help_outline,
                title: 'Mot de passe oublié',
                subtitle: 'Recevoir un lien de réinitialisation par e-mail',
                onTap: () => sendPasswordReset(context, ref),
              ),
              _ProfileTile(
                icon: Icons.mark_email_read_outlined,
                title: 'Vérifier mon adresse e-mail',
                subtitle: (user?.emailVerified ?? false)
                    ? 'Adresse e-mail vérifiée'
                    : 'Adresse e-mail non vérifiée',
                onTap: (user?.emailVerified ?? false)
                    ? null
                    : () => sendEmailVerification(context, ref),
              ),
              _ProfileTile(
                icon: Icons.dark_mode_outlined,
                title: 'Thème',
                subtitle: themeLabel(themeMode),
                onTap: () => chooseTheme(context, ref, themeMode),
              ),
              _ProfileTile(
                icon: Icons.delete_forever_outlined,
                title: 'Supprimer mon compte',
                titleColor: AppPalette.error,
                onTap: () => deleteAccount(context, ref),
              ),
              _ProfileTile(
                icon: Icons.logout,
                title: 'Déconnexion',
                titleColor: AppPalette.error,
                onTap: () => ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String themeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => 'Clair',
    ThemeMode.dark => 'Sombre',
    ThemeMode.system => 'Système',
  };
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _runAuthAction(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  await action();

  if (!context.mounted) {
    return false;
  }

  final error = ref.read(authNotifierProvider).error;

  if (error != null) {
    _showMessage(context, authErrorMessage(error));
    return false;
  }

  return true;
}

Future<void> editDisplayName(
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
        decoration: const InputDecoration(labelText: 'Nom affiché'),
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

  if (name == null || name.isEmpty || !context.mounted) {
    return;
  }

  final success = await _runAuthAction(
    context,
    ref,
    () => ref
        .read(authNotifierProvider.notifier)
        .changeDisplayName(displayName: name),
  );

  if (success && context.mounted) {
    _showMessage(context, 'Nom mis à jour.');
  }
}

Future<void> changePassword(BuildContext context, WidgetRef ref) async {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var showCurrentPassword = false;
  var showNewPassword = false;
  var showConfirmPassword = false;

  final credentials = await showDialog<Map<String, String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final currentPassword = currentPasswordController.text;
          final newPassword = newPasswordController.text;
          final confirmPassword = confirmPasswordController.text;

          final passwordsMatch =
              newPassword.isNotEmpty &&
              confirmPassword.isNotEmpty &&
              newPassword == confirmPassword;

          final passwordsDoNotMatch =
              confirmPassword.isNotEmpty && newPassword != confirmPassword;

          final valid =
              currentPassword.isNotEmpty &&
              newPassword.length >= 6 &&
              passwordsMatch;

          return AlertDialog(
            title: const Text('Changer le mot de passe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    autofocus: true,
                    obscureText: !showCurrentPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showCurrentPassword = !showCurrentPassword;
                          });
                        },
                        icon: Icon(
                          showCurrentPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: !showNewPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      helperText: 'Au moins 6 caractères',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showNewPassword = !showNewPassword;
                          });
                        },
                        icon: Icon(
                          showNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        },
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (passwordsDoNotMatch) ...[
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Les mots de passe ne correspondent pas.',
                        style: TextStyle(color: AppPalette.error, fontSize: 12),
                      ),
                    ),
                  ],
                  if (passwordsMatch) ...[
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Les mots de passe correspondent.',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: valid
                    ? () {
                        Navigator.pop(dialogContext, {
                          'current': currentPassword,
                          'new': newPassword,
                        });
                      }
                    : null,
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );

  currentPasswordController.dispose();
  newPasswordController.dispose();
  confirmPasswordController.dispose();

  if (credentials == null || !context.mounted) {
    return;
  }

  final currentPassword = credentials['current'];
  final newPassword = credentials['new'];

  if (currentPassword == null ||
      newPassword == null ||
      currentPassword.isEmpty ||
      newPassword.length < 6) {
    return;
  }

  await ref
      .read(authNotifierProvider.notifier)
      .changePasswordWithReauthentication(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  if (!context.mounted) {
    return;
  }

  final error = ref.read(authNotifierProvider).error;

  if (error != null) {
    _showMessage(context, authErrorMessage(error));
    return;
  }

  _showMessage(context, 'Mot de passe mis à jour.');
}

Future<void> sendPasswordReset(BuildContext context, WidgetRef ref) async {
  final email = ref.read(currentUserProvider)?.email;

  if (email == null || email.isEmpty) {
    _showMessage(context, 'Aucune adresse e-mail n’est disponible.');
    return;
  }

  final success = await _runAuthAction(
    context,
    ref,
    () => ref
        .read(authNotifierProvider.notifier)
        .sendPasswordResetEmail(email: email),
  );

  if (success && context.mounted) {
    _showMessage(context, 'Un lien de réinitialisation a été envoyé à $email.');
  }
}

Future<void> sendEmailVerification(BuildContext context, WidgetRef ref) async {
  final success = await _runAuthAction(
    context,
    ref,
    () => ref.read(authNotifierProvider.notifier).sendEmailVerification(),
  );

  if (success && context.mounted) {
    _showMessage(context, 'Un e-mail de vérification a été envoyé.');
  }
}

Future<void> deleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer mon compte'),
      content: const Text(
        'Cette action est définitive. Votre compte et vos accès '
        'seront supprimés.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppPalette.error),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final success = await _runAuthAction(
    context,
    ref,
    () => ref.read(authNotifierProvider.notifier).deleteAccount(),
  );

  if (success && context.mounted) {
    _showMessage(context, 'Compte supprimé.');
  }
}

Future<void> chooseTheme(
  BuildContext context,
  WidgetRef ref,
  ThemeMode currentMode,
) async {
  final selected = await showDialog<ThemeMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Thème'),
      children: [
        for (final mode in ThemeMode.values)
          ListTile(
            title: Text(themeLabel(mode)),
            trailing: mode == currentMode
                ? const Icon(Icons.check, color: AppPalette.primary)
                : null,
            onTap: () => Navigator.pop(context, mode),
          ),
      ],
    ),
  );

  if (selected != null) {
    await ref.read(themeModeProvider.notifier).setThemeMode(selected);
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = titleColor;

    return ListTile(
      leading: Icon(icon, color: color ?? AppPalette.primary),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
