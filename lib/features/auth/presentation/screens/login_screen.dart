import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
      context.go('/home');
    }
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
          case 'invalid-credential':
          case 'wrong-password':
          case 'user-not-found':
            return 'Invalid email or password.';
          case 'invalid-email':
            return 'Please enter a valid email address.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'too-many-requests':
            return 'Too many attempts. Please try again later.';
          case 'network-request-failed':
            return 'Network error. Check your internet connection.';
          default:
            return e.message ?? 'Unable to sign in.';
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
      title: 'Welcome back',
      subtitle: 'Sign in to access your urban resilience dashboard.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: isLoading
                ? null
                : () => context.push('/register'),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                controller: _emailController,
                label: 'Email',
                hint: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHint: AutofillHints.email,
                enabled: !isLoading,
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
              const SizedBox(height: 16),
              PasswordField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                textInputAction: TextInputAction.done,
                autofillHint: AutofillHints.password,
                enabled: !isLoading,
                onFieldSubmitted: (_) => _login(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.push('/forgot-password'),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 16),
              AuthButton(
                label: 'Sign in',
                icon: Icons.login,
                isLoading: isLoading,
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
