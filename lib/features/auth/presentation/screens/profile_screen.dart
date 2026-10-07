import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/core/theme/theme_provider.dart';
import 'package:urban_resilience/features/auth/presentation/auth_error_message.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';

import 'package:firebase_auth/firebase_auth.dart';

/// Firestore-backed boolean preference notifier that synchronizes with SharedPreferences.
class FirestoreBoolPrefNotifier extends Notifier<bool> {
  FirestoreBoolPrefNotifier._internal({
    required this.auth,
    required this.firestore,
    required this.key,
    required this.defaultValue,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final String key;
  final bool defaultValue;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _firestoreSub;

  @override
  bool build() {
    // Initialize with default value, then load asynchronously
    _init();
    return defaultValue;
  }

  void _init() {
    // Listen to auth state changes
    _authSub = auth.authStateChanges().listen(_onAuthStateChanged);
    // Load initial value for current user (if any)
    _loadValue();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    // Cancel any existing Firestore listener
    await _firestoreSub?.cancel();

    if (user == null) {
      // User signed out -> fall back to SharedPreferences
      await _loadFromSharedPreferences();
      return;
    }

    // User signed in: load from Firestore (or fallback) and set up real-time listener
    final uid = user.uid;
    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('notificationPreferences')
        .doc('prefs');

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();
        final value = data?[key] as bool?;
        if (value != null) {
          state = value;
          await _saveToSharedPreferences(value);
        } else {
          await _loadFromSharedPreferences();
          await _saveToFirestore(state);
        }
      } else {
        // Document doesn't exist -> migrate from SharedPreferences
        await _loadFromSharedPreferences();
        await _saveToFirestore(state);
      }
    } catch (e) {
      debugPrint('Failed to load preference $key from Firestore: $e');
      await _loadFromSharedPreferences();
    }

    // Real-time listener for cross-device sync
    _firestoreSub = firestore
        .collection('users')
        .doc(uid)
        .collection('notificationPreferences')
        .doc('prefs')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final value = data?[key] as bool?;
        if (value != null && value != state) {
          state = value;
          _saveToSharedPreferences(value);
        }
      }
    });
  }

  Future<void> _loadValue() async {
    final user = auth.currentUser;
    if (user == null) {
      await _loadFromSharedPreferences();
      return;
    }

    try {
      final doc = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('notificationPreferences')
          .doc('prefs')
          .get();

      if (doc.exists) {
        final data = doc.data();
        final value = data?[key] as bool?;
        if (value != null) {
          state = value;
          await _saveToSharedPreferences(value);
          return;
        }
      }

      // Document doesn't exist or key missing: fall back to SharedPreferences
      await _loadFromSharedPreferences();
      // Then save the fallback value to Firestore
      await _saveToFirestore(state);
    } catch (e) {
      debugPrint('Failed to load preference $key from Firestore: $e');
      await _loadFromSharedPreferences();
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key) ?? defaultValue;
    state = value;
  }

  Future<void> _saveToSharedPreferences(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveToFirestore(bool value) async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('notificationPreferences')
          .doc('prefs')
          .set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save preference $key to Firestore: $e');
      rethrow;
    }
  }

  void setValue(bool value) {
    final oldValue = state;
    state = value;

    _saveToSharedPreferences(value).catchError((e) {
      debugPrint('Failed to save $key to SharedPreferences: $e');
    });

    _saveToFirestore(value).catchError((e) {
      state = oldValue;
      _saveToSharedPreferences(oldValue);
      debugPrint('Failed to save $key to Firestore: $e');
    });
  }

  void dispose() {
    _authSub?.cancel();
    _firestoreSub?.cancel();
  }
}

final profileNearbyAlertsProvider = NotifierProvider<FirestoreBoolPrefNotifier, bool>(() {
  return FirestoreBoolPrefNotifier._internal(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    key: 'pref_nearby_alerts',
    defaultValue: true,
  );
});

final profileReportUpdatesProvider = NotifierProvider<FirestoreBoolPrefNotifier, bool>(() {
  return FirestoreBoolPrefNotifier._internal(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    key: 'pref_report_updates',
    defaultValue: true,
  );
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final place = ref.watch(selectedPlaceProvider);
    final nearbyAlerts = ref.watch(profileNearbyAlertsProvider);
    final reportUpdates = ref.watch(profileReportUpdatesProvider);

    final displayName = user?.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? 'Utilisateur'
        : displayName;
    final email = user?.email ?? '';
    final cityLabel = place?.label.trim().isNotEmpty == true
        ? place!.label
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/map');
            }
          },
        ),
        title: Text(
          'Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const SizedBox(height: 8),
                _IdentityCard(
                  name: name,
                  email: email,
                  onEdit: () =>
                      editDisplayName(context, ref, displayName ?? ''),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Compte',
                  children: [
                    _AccountRow(
                      iconAsset: 'assets/icons/lock-keyhole.svg',
                      title: 'Changer le mot de passe',
                      onTap: () => changePassword(context, ref),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    _AccountRow(
                      iconAsset: 'assets/icons/profile-help.svg',
                      title: 'Mot de passe oublié',
                      subtitle:
                          'Recevoir un lien de réinitialisation par e-mail',
                      onTap: () => sendPasswordReset(context, ref),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    _AccountRow(
                      iconAsset: 'assets/icons/mail.svg',
                      title: 'Vérifier mon adresse e-mail',
                      subtitle: (user?.emailVerified ?? false)
                          ? 'Adresse e-mail vérifiée'
                          : 'Adresse e-mail non vérifiée',
                      showChevron: !(user?.emailVerified ?? false),
                      onTap: (user?.emailVerified ?? false)
                          ? null
                          : () => sendEmailVerification(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Préférences de notifications',
                  children: [
                    _ToggleRow(
                      title: 'Alertes près de chez moi',
                      subtitle: cityLabel == null
                          ? 'Risques autour de vous'
                          : 'Risques autour de $cityLabel',
                      value: nearbyAlerts,
                      onChanged: (value) => ref
                          .read(profileNearbyAlertsProvider.notifier)
                          .setValue(value),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    _ToggleRow(
                      title: 'Suivi de mes signalements',
                      subtitle: 'Validation et changements de statut',
                      value: reportUpdates,
                      onChanged: (value) => ref
                          .read(profileReportUpdatesProvider.notifier)
                          .setValue(value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Thème',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                      child: _ThemeSegment(
                        mode: themeMode,
                        onSelect: (mode) => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(mode),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LogoutButton(
                  onTap: () =>
                      ref.read(authNotifierProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const ReportNavigation(selected: CitizenNavTab.profil),
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.onEdit,
  });

  final String name;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              _initials(name),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: scheme.primaryContainer,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/profile-pencil.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      scheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.showChevron = true,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String? subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                scheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: scheme.onPrimary,
            activeTrackColor: scheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.mode, required this.onSelect});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeChip(
              key: const ValueKey('theme-light'),
              label: 'Clair',
              asset: 'assets/icons/profile-sun.svg',
              selected: !isDark,
              onTap: () => onSelect(ThemeMode.light),
            ),
          ),
          Expanded(
            child: _ThemeChip(
              key: const ValueKey('theme-dark'),
              label: 'Sombre',
              asset: 'assets/icons/profile-moon.svg',
              selected: isDark,
              onTap: () => onSelect(ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    super.key,
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedFg = scheme.primary;
    final mutedFg = scheme.onSurfaceVariant;
    final selectedBg = selected ? scheme.surface : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selectedBg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              asset,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                selected ? selectedFg : mutedFg,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? scheme.onSurface : mutedFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/profile-logout.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  scheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Se déconnecter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _EditDisplayNameDialog(currentName: currentName),
  );

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

class _EditDisplayNameDialog extends StatefulWidget {
  const _EditDisplayNameDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditDisplayNameDialog> createState() => _EditDisplayNameDialogState();
}

class _EditDisplayNameDialogState extends State<_EditDisplayNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le nom'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(labelText: 'Nom affiché'),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

Future<void> changePassword(BuildContext context, WidgetRef ref) async {
  final credentials = await showDialog<Map<String, String>>(
    context: context,
    builder: (context) => const _ChangePasswordDialog(),
  );

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

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  var _showCurrentPassword = false;
  var _showNewPassword = false;
  var _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final passwordsMatch = newPassword.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        newPassword == confirmPassword;

    final passwordsDoNotMatch =
        confirmPassword.isNotEmpty && newPassword != confirmPassword;

    final valid = currentPassword.isNotEmpty &&
        newPassword.length >= 6 &&
        passwordsMatch;

    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              autofocus: true,
              obscureText: !_showCurrentPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                helperText: 'Au moins 6 caractères',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _showConfirmPassword
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: valid
              ? () {
                  Navigator.pop(context, {
                    'current': currentPassword,
                    'new': newPassword,
                  });
                }
              : null,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
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
