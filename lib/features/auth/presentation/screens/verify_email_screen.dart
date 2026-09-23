import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_scaffold.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends ConsumerState<VerifyEmailScreen> {
  bool _isRefreshing = false;
  bool _isSending = false;

  Future<void> _sendVerificationEmail() async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    await ref
        .read(authNotifierProvider.notifier)
        .sendEmailVerification();

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    setState(() {
      _isSending = false;
    });

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    _showMessage('Verification email sent.');
  }

  Future<void> _checkVerificationStatus() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload();
    }

    if (!mounted) {
      return;
    }

    ref.invalidate(authStateChangesProvider);

    final updatedUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _isRefreshing = false;
    });

    if (updatedUser?.emailVerified == true) {
      context.go('/home');
      return;
    }

    _showMessage(
      'Your email is not verified yet. Please check your inbox.',
    );
  }

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    context.go('/login');
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
    final message = _getAuthErrorMessage(error);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _getAuthErrorMessage(Object? error) {
    switch (error) {
      case FirebaseAuthException e:
        switch (e.code) {
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          case 'too-many-requests':
            return 'Too many requests. Please try again later.';
          default:
            return e.message ?? 'Unable to complete the action.';
        }
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isRefreshing || _isSending;

    return AuthScaffold(
      title: 'Verify your email',
      subtitle:
          'Please verify your email address before accessing Urban Resilience.',
      footer: TextButton.icon(
        onPressed: isLoading ? null : _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Sign out'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Check your inbox',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'We sent a verification link to your email address. '
            'Open the email and follow the link to verify your account.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          AuthButton(
            label: 'I verified my email',
            icon: Icons.verified_outlined,
            isLoading: _isRefreshing,
            onPressed: _checkVerificationStatus,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _sendVerificationEmail,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Resend verification email'),
          ),
          const SizedBox(height: 16),
          Text(
            'Already verified? Tap "I verified my email" to refresh your status.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}