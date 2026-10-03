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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref
        .read(authNotifierProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
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

    context.go('/verify-email');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Créer un compte',
      subtitle:
          'Rejoignez-nous pour rester informé(e) des risques dans votre zone.',
      footer: Column(
        children: [
          const AuthPrivacyNote(),
          const SizedBox(height: 12),
          AuthTextLink(
            leading: 'Déjà un compte ?',
            action: 'Se connecter',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
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
                label: 'Nom complet',
                controller: _nameController,
                hintText: 'Votre nom',
                prefix: const AuthIcon(
                  asset: 'assets/icons/user.svg',
                  color: AppPalette.primary,
                  size: 18,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
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
                  if (value == null || value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthButton(
                text: 'Créer mon compte',
                isLoading: _isLoading,
                icon: const AuthIcon(
                  asset: 'assets/icons/user-plus.svg',
                  color: Colors.white,
                ),
                onPressed: _onRegister,
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
