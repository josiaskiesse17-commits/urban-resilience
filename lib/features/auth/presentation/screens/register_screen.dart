import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isSubmitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      final authState = ref.read(authNotifierProvider);

      if (authState.hasError) {
        _showError(authState.error);
        return;
      }

      if (authState.hasValue && authState.value != null) {
        await _showVerificationMessage();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showVerificationMessage() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify your email'),
          content: const Text(
            'Your account has been created. '
            'We sent a verification email to your email address. '
            'Please verify it before continuing.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    context.go('/home');
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
          case 'email-already-in-use':
            return 'An account already exists with this email.';
          case 'invalid-email':
            return 'Please enter a valid email address.';
          case 'weak-password':
            return 'The password is too weak.';
          case 'operation-not-allowed':
            return 'Email/password authentication is not enabled.';
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          case 'too-many-requests':
            return 'Too many attempts. Please try again later.';
          default:
            return e.message ?? 'Unable to create your account.';
        }
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Name is required.';
    }

    if (name.length < 2) {
      return 'Name must contain at least 2 characters.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
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
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 8) {
      return 'Password must contain at least 8 characters.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Join Urban Resilience and stay informed about local risks.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () => context.go('/login'),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Enter your name',
              prefixIcon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a password',
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Enter your password again',
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: _validateConfirmPassword,
            ),
            const SizedBox(height: 24),
            AuthButton(
              label: 'Create account',
              icon: Icons.person_add_outlined,
              isLoading: _isSubmitting,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
