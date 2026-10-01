import 'package:flutter/material.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_button.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_scaffold.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Vérifiez votre e-mail',
      subtitle: 'Un e-mail de confirmation a été envoyé à votre adresse.',
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppPalette.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 64, color: AppPalette.primary),
            const SizedBox(height: 16),
            const Text(
              'Cliquez sur le lien reçu pour valider votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.textMuted),
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'J\'ai vérifié mon e-mail',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}