import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/auth/presentation/auth_error_message.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_button.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_field.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_icon.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      setState(() {
        _isLoading = false;
        _error = authErrorMessage(authState.error);
      });
      return;
    }

    context.go('/location');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Heureux de vous revoir',
      subtitle: 'Connectez-vous pour retrouver vos alertes locales et vos préférences.',
      footer: Column(
        children: [
          const AuthPrivacyNote(),
          const SizedBox(height: 12),
          AuthTextLink(
            leading: 'Pas encore de compte ?',
            action: 'Créer un compte',
            onPressed: () => context.push('/register'),
          ),
        ],
      ),
      child: AuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                label: 'Adresse e-mail',
                controller: _emailController,
                hintText: 'votreemail@gmail.com',
                prefix: const AuthIcon(
                  asset: 'assets/icons/mail.svg',
                  color: AppPalette.primary,
                  size: 18,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Adresse e-mail invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre mot de passe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/forgot-password'),
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AuthButton(
                text: 'Se connecter',
                isLoading: _isLoading,
                icon: const AuthIcon(
                  asset: 'assets/icons/log-in.svg',
                  color: Colors.white,
                ),
                onPressed: _onLogin,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.error,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
