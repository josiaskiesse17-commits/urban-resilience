import 'package:flutter/material.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/auth/presentation/widgets/auth_icon.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
                    child: Column(
                      mainAxisAlignment: footer == null
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceBetween,
                      children: [
                        _AuthIntro(title: title, subtitle: subtitle),
                        if (footer == null) ...[
                          const SizedBox(height: 28),
                          child,
                        ] else ...[
                          child,
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const _AuthIntro({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const AuthIcon(
                asset: 'assets/icons/shield-check.svg',
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'urban-resilience',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppPalette.textDark,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Prévenir. Comprendre. Agir.',
          style: TextStyle(
            fontSize: 13,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppPalette.textDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthPrivacyNote extends StatelessWidget {
  const AuthPrivacyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.infoBoxBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthIcon(
            asset: 'assets/icons/shield-check-small.svg',
            color: AppPalette.infoText,
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Vos informations restent privées et protégées.',
              style: TextStyle(
                fontSize: 11,
                color: AppPalette.infoText,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextLink extends StatelessWidget {
  final String leading;
  final String action;
  final VoidCallback onPressed;

  const AuthTextLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leading,
          style: const TextStyle(
            fontSize: 13,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: onPressed,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppPalette.primary,
            ),
          ),
        ),
      ],
    );
  }
}
