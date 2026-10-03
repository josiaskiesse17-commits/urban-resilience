import 'package:flutter/material.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_button.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_field.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_scaffold.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State {
  final _emailController = TextEditingController();
  final bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle:
          'Saisissez votre e-mail pour recevoir un lien\nde réinitialisation.',
      child: Container(
        padding: const EdgeInsets.all(24.0),
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
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'Envoyer le lien',
              isLoading: _isLoading,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
