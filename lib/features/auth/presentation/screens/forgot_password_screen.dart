import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:urban_resilience/features/auth/presentation/auth_error_message.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_button.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_field.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Veuillez saisir votre adresse e-mail.';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _error = 'Adresse e-mail invalide.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(
          email: email,
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

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Un lien de réinitialisation a été envoyé à $email.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle:
          'Saisissez votre e-mail pour recevoir un lien de réinitialisation.',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            AuthField(
              label: 'Adresse e-mail',
              controller: _emailController,
              hintText: 'votreemail@gmail.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'Envoyer le lien',
              isLoading: _isLoading,
              onPressed: _sendResetLink,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
