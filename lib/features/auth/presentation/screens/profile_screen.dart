import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../domain/app_user.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_field.dart';
import '../widgets/password_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _nameInitialized = false;

  bool _isSavingName = false;
  bool _isChangingPassword = false;
  bool _isSendingVerification = false;
  bool _isRefreshingVerification = false;
  bool _isLoggingOut = false;
  bool _isDeletingAccount = false;
  bool _isReauthenticating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isBusy =>
      _isSavingName ||
      _isChangingPassword ||
      _isSendingVerification ||
      _isRefreshingVerification ||
      _isLoggingOut ||
      _isDeletingAccount ||
      _isReauthenticating;

  Future<void> _changeDisplayName() async {
    if (_isBusy) return;

    if (!_nameFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSavingName = true;
    });

    await ref.read(authNotifierProvider.notifier).changeDisplayName(
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    setState(() {
      _isSavingName = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    _showMessage('Name updated successfully.');
  }

  Future<void> _changePassword() async {
    if (_isBusy) return;

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final newPassword = _passwordController.text;
    final notifier = ref.read(authNotifierProvider.notifier);

    setState(() {
      _isChangingPassword = true;
    });

    await notifier.changePassword(
      newPassword: newPassword,
    );

    if (!mounted) return;

    var authState = ref.read(authNotifierProvider);

    if (_requiresRecentLogin(authState.error)) {
      setState(() {
        _isChangingPassword = false;
      });

      final reauthenticated = await _reauthenticate();

      if (!reauthenticated || !mounted) {
        return;
      }

      setState(() {
        _isChangingPassword = true;
      });

      await notifier.changePassword(
        newPassword: newPassword,
      );

      if (!mounted) return;

      authState = ref.read(authNotifierProvider);
    }

    setState(() {
      _isChangingPassword = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    _passwordController.clear();
    _confirmPasswordController.clear();

    _showMessage('Password updated successfully.');
  }

  Future<void> _sendVerificationEmail() async {
    if (_isBusy) return;

    setState(() {
      _isSendingVerification = true;
    });

    await ref
        .read(authNotifierProvider.notifier)
        .sendEmailVerification();

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    setState(() {
      _isSendingVerification = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    _showMessage('Verification email sent.');
  }

  Future<void> _refreshVerificationStatus() async {
    if (_isBusy) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return;
    }

    setState(() {
      _isRefreshingVerification = true;
    });

    try {
      await firebaseUser.reload();

      if (!mounted) return;

      ref.invalidate(authStateChangesProvider);

      final updatedUser = FirebaseAuth.instance.currentUser;

      setState(() {
        _isRefreshingVerification = false;
      });

      if (updatedUser?.emailVerified == true) {
        _showMessage('Your email is verified.');
      } else {
        _showMessage('Your email is not verified yet.');
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isRefreshingVerification = false;
      });

      _showError(error);
    }
  }

  Future<void> _logout() async {
    if (_isBusy) return;

    setState(() {
      _isLoggingOut = true;
    });

    await ref.read(authNotifierProvider.notifier).logout();

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);

    setState(() {
      _isLoggingOut = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    context.go('/login');
  }

  Future<void> _deleteAccount() async {
    if (_isBusy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently deletes your account. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final notifier = ref.read(authNotifierProvider.notifier);

    setState(() {
      _isDeletingAccount = true;
    });

    await notifier.deleteAccount();

    if (!mounted) return;

    var authState = ref.read(authNotifierProvider);

    if (_requiresRecentLogin(authState.error)) {
      setState(() {
        _isDeletingAccount = false;
      });

      final reauthenticated = await _reauthenticate();

      if (!reauthenticated || !mounted) {
        return;
      }

      setState(() {
        _isDeletingAccount = true;
      });

      await notifier.deleteAccount();

      if (!mounted) return;

      authState = ref.read(authNotifierProvider);
    }

    setState(() {
      _isDeletingAccount = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    context.go('/login');
  }

  Future<bool> _reauthenticate() async {
    if (_isReauthenticating) {
      return false;
    }

    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm your password'),
          content: PasswordField(
            controller: passwordController,
            label: 'Current password',
            hint: 'Enter your current password',
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  return;
                }

                Navigator.of(context).pop(
                  passwordController.text,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();

    if (password == null || password.isEmpty || !mounted) {
      return false;
    }

    setState(() {
      _isReauthenticating = true;
    });

    await ref.read(authNotifierProvider.notifier).reauthenticate(
          password: password,
        );

    if (!mounted) {
      return false;
    }

    final authState = ref.read(authNotifierProvider);

    setState(() {
      _isReauthenticating = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return false;
    }

    return true;
  }

  bool _requiresRecentLogin(Object? error) {
    return error is FirebaseAuthException &&
        error.code == 'requires-recent-login';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(Object? error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_getAuthErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _getAuthErrorMessage(Object? error) {
    switch (error) {
      case FirebaseAuthException e:
        switch (e.code) {
          case 'requires-recent-login':
            return 'For security, please confirm your password and try again.';
          case 'wrong-password':
          case 'invalid-credential':
            return 'The password you entered is incorrect.';
          case 'weak-password':
            return 'The password is too weak.';
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          case 'too-many-requests':
            return 'Too many requests. Please try again later.';
          case 'user-not-found':
            return 'No authenticated user was found.';
          case 'missing-email':
            return 'No email address is associated with this account.';
          default:
            return e.message ?? 'Unable to complete the action.';
        }
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.value;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_nameInitialized) {
      _nameController.text = user.displayName ?? '';
      _nameInitialized = true;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isEmailVerified =
        firebaseUser?.emailVerified ?? user.emailVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 24),
                  _buildVerificationCard(context, isEmailVerified),
                  const SizedBox(height: 24),
                  _buildAppearanceSection(context),
                  const SizedBox(height: 24),
                  _buildAccountSection(context, user),
                  const SizedBox(height: 24),
                  _buildPasswordSection(context),
                  const SizedBox(height: 24),
                  _buildDangerSection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppUser user,
  ) {
    final theme = Theme.of(context);
    final displayName = user.displayName?.trim();

    final initials = displayName != null && displayName.isNotEmpty
        ? displayName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join()
        : user.email.isNotEmpty
            ? user.email[0].toUpperCase()
            : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initials,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName?.isNotEmpty == true
              ? displayName!
              : 'Urban Resilience user',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerificationCard(
    BuildContext context,
    bool isEmailVerified,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isEmailVerified
                  ? Icons.verified_outlined
                  : Icons.warning_amber_outlined,
              color: isEmailVerified
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEmailVerified
                        ? 'Email verified'
                        : 'Email not verified',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEmailVerified
                        ? 'Your email address has been verified.'
                        : 'Verify your email to secure your account.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (!isEmailVerified) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _isBusy
                              ? null
                              : _sendVerificationEmail,
                          child: _isSendingVerification
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Resend email'),
                        ),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : _refreshVerificationStatus,
                          child: _isRefreshingVerification
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('I verified it'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how Urban Resilience looks on your device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (mode) {
                if (mode == null) {
                  return;
                }

                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(mode);
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    title: Text('System default'),
                    subtitle: Text('Follow your device settings'),
                    secondary: Icon(
                      Icons.settings_brightness_outlined,
                    ),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    title: Text('Light'),
                    secondary: Icon(
                      Icons.light_mode_outlined,
                    ),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    title: Text('Dark'),
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    AppUser user,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _nameFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Account information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 20),
              AuthField(
                controller: _nameController,
                label: 'Display name',
                hint: 'Enter your name',
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.done,
                enabled: !_isBusy,
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Name is required.';
                  }

                  if (name.length < 2) {
                    return 'Name must contain at least 2 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                child: Text(user.email),
              ),
              const SizedBox(height: 20),
              AuthButton(
                label: 'Save name',
                icon: Icons.save_outlined,
                isLoading: _isSavingName,
                onPressed: _changeDisplayName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change password',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a new password for your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: _passwordController,
                label: 'New password',
                hint: 'Enter a new password',
                textInputAction: TextInputAction.next,
                enabled: !_isBusy,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }

                  if (value.length < 8) {
                    return 'Password must contain at least 8 characters.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Enter the password again',
                textInputAction: TextInputAction.done,
                enabled: !_isBusy,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }

                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              AuthButton(
                label: 'Update password',
                icon: Icons.lock_reset_outlined,
                isLoading: _isChangingPassword,
                onPressed: _changePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Account actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isBusy ? null : _logout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isBusy ? null : _deleteAccount,
              icon: _isDeletingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
              label: Text(
                'Delete account',
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
