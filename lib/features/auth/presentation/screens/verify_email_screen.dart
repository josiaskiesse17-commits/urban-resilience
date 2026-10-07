import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:urban_resilience/features/auth/presentation/auth_error_message.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_button.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_scaffold.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;
  String? _error;

  Future<void> _checkVerification() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    await ref.read(authNotifierProvider.notifier).refreshUser();

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    if (authState.hasError) {
      setState(() {
        _checking = false;
        _error = authErrorMessage(authState.error);
      });
      return;
    }

    final user = ref.read(currentUserProvider);

    if (user?.emailVerified ?? false) {
      setState(() {
        _checking = false;
      });

      return;
    }

    setState(() {
      _checking = false;
      _error =
          'Votre adresse e-mail n’est pas encore vérifiée. '
          'Cliquez sur le lien reçu puis réessayez.';
    });
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resending = true;
      _error = null;
    });

    await ref.read(authNotifierProvider.notifier).sendEmailVerification();

    if (!mounted) {
      return;
    }

    final authState = ref.read(authNotifierProvider);

    if (authState.hasError) {
      setState(() {
        _resending = false;
        _error = authErrorMessage(authState.error);
      });
      return;
    }

    setState(() {
      _resending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Un nouvel e-mail de vérification a été envoyé.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Vérifiez votre e-mail',
      subtitle: 'Un e-mail de confirmation a été envoyé à votre adresse.',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Cliquez sur le lien reçu pour valider votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AuthButton(
              text: 'J’ai vérifié mon e-mail',
              isLoading: _checking,
              onPressed: _checkVerification,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resending ? null : _resendVerification,
              child: Text(
                _resending
                    ? 'Renvoi en cours...'
                    : 'Renvoyer l’e-mail de vérification',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
