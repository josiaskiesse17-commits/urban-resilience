import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    if (authState.hasError) {
      _showError(authState.error);
      return;
    }

    setState(() {
      _emailSent = true;
    });
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
          case 'invalid-email':
            return 'Please enter a valid email address.';
          case 'user-not-found':
            return 'No account was found with this email.';
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          case 'too-many-requests':
            return 'Too many requests. Please try again later.';
          default:
            return e.message ?? 'Unable to send the reset email.';
        }
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return AuthScaffold(
      title: 'Reset your password',
      subtitle: _emailSent
          ? 'Check your inbox for instructions to create a new password.'
          : 'Enter your email and we will send you a password reset link.',
      footer: TextButton.icon(
        onPressed: isLoading
            ? null
            : () => context.go('/login'),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to sign in'),
      ),
      child: _emailSent
          ? _buildSuccessContent(context)
          : _buildForm(isLoading),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHint: AutofillHints.email,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _sendResetEmail(),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Email is required.';
              }

              final emailRegex = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              );

              if (!emailRegex.hasMatch(email)) {
                return 'Enter a valid email address.';
              }

              return null;
            },
          ),
          const SizedBox(height: 24),
          AuthButton(
            label: 'Send reset link',
            icon: Icons.mail_outline,
            isLoading: isLoading,
            onPressed: _sendResetEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 36,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to:',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'If you do not see the email, check your spam or junk folder.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
              });
            },
            child: const Text('Try another email'),
          ),
        ),
      ],
    );
  }
}
