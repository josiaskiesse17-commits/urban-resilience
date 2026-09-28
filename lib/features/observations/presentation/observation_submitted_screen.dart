import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ObservationSubmittedScreen extends StatelessWidget {
  const ObservationSubmittedScreen({
    super.key,
    this.reference,
  });

  final String? reference;

  static const Color primary = Color(0xFF147B83);
  static const Color primaryLight = Color(0xFFDCEFF1);
  static const Color textDark = Color(0xFF12343B);
  static const Color textGrey = Color(0xFF64777C);

  @override
  Widget build(BuildContext context) {
    final displayReference =
        reference ?? 'VIG-${DateTime.now().year}-0000';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FBFC),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 35, 28, 30),
          child: Column(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryLight,
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: primary,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              const Text(
                'Merci, votre\nsignalement est reçu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 34,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Il est en cours de vérification par nos équipes '
                'et les sources locales disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 17,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 26),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFD5E0E2),
                  ),
                ),
                child: Text(
                  '#  $displayReference',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFD5E0E2),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suivi du signalement',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 25),
                    _TimelineItem(
                      icon: Icons.check,
                      title: 'Signalement transmis',
                      subtitle: 'Votre signalement a bien été envoyé.',
                      active: true,
                    ),
                    _TimelineConnector(),
                    _TimelineItem(
                      icon: Icons.refresh,
                      title: 'Vérification en cours',
                      subtitle: 'Délai moyen : moins de 20 min',
                      active: true,
                    ),
                    _TimelineConnector(),
                    _TimelineItem(
                      icon: null,
                      title: 'Décision et publication éventuelle',
                      subtitle: null,
                      active: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: FilledButton.icon(
                  onPressed: () => context.go('/observations'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(
                    Icons.checklist_outlined,
                    size: 25,
                  ),
                  label: const Text(
                    'Voir mes signalements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 62,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFD5E0E2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(
                    Icons.map_outlined,
                    size: 25,
                  ),
                  label: const Text(
                    'Retour à la carte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool active;

  static const Color primary = Color(0xFF147B83);
  static const Color primaryLight = Color(0xFFDCEFF1);
  static const Color textDark = Color(0xFF12343B);
  static const Color textGrey = Color(0xFF64777C);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? primary : primaryLight,
            border: active
                ? null
                : Border.all(
                    color: const Color(0xFFD5E0E2),
                    width: 3,
                  ),
          ),
          child: icon == null
              ? null
              : Icon(
                  icon,
                  color: active ? Colors.white : primary,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: active ? textDark : textGrey,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 23,
        top: 5,
        bottom: 5,
      ),
      width: 3,
      height: 28,
      color: const Color(0xFFD5E0E2),
    );
  }
}