import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ObservationSuccessScreen extends StatelessWidget {
  final String observationId;

  const ObservationSuccessScreen({
    super.key,
    required this.observationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            50,
            24,
            30,
          ),
          child: Column(
            children: [
              // ---------------------------------------------------------
              // CHECK
              // ---------------------------------------------------------
              Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFDDEFF1),
                ),
                child: Center(
                  child: Container(
                    width: 145,
                    height: 145,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF197A83),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 75,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              const Text(
                'Merci, votre\nsignalement est reçu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123C43),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Il est en cours de vérification par nos équipes et les sources locales disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: Color(0xFF60777B),
                ),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // NUMERO
              // ---------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFD3E1E3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '#',
                      style: TextStyle(
                        color: Color(0xFF197A83),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatReference(observationId),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17353B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ---------------------------------------------------------
              // SUIVI
              // ---------------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFD3E1E3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suivi du signalement',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17353B),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _Step(
                      icon: Icons.check,
                      active: true,
                      title: 'Signalement transmis',
                      subtitle: 'Votre signalement a bien été enregistré.',
                    ),

                    _Connector(),

                    const _Step(
                      icon: Icons.refresh,
                      active: true,
                      title: 'Vérification en cours',
                      subtitle: 'Délai moyen : moins de 20 min',
                    ),

                    _Connector(),

                    const _Step(
                      icon: null,
                      active: false,
                      title: 'Décision et publication éventuelle',
                      subtitle: null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------------------------------------------------------
              // MES SIGNALEMENTS
              // ---------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 64,
                child: FilledButton.icon(
                  onPressed: () {
                    context.go('/observations');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF197A83),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(
                    Icons.checklist_outlined,
                    size: 27,
                  ),
                  label: const Text(
                    'Voir mes signalements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------------------------------------------------
              // RETOUR CARTE
              // ---------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go('/map');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFD3E1E3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(
                    Icons.map_outlined,
                    color: Color(0xFF197A83),
                  ),
                  label: const Text(
                    'Retour à la carte',
                    style: TextStyle(
                      color: Color(0xFF197A83),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
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

  String _formatReference(String id) {
    if (id.length <= 8) {
      return 'VIG-$id';
    }

    return 'VIG-${id.substring(0, 8).toUpperCase()}';
  }
}

class _Step extends StatelessWidget {
  final IconData? icon;
  final bool active;
  final String title;
  final String? subtitle;

  const _Step({
    required this.icon,
    required this.active,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFF197A83)
                : const Color(0xFFF2F6F7),
            border: Border.all(
              color: active
                  ? const Color(0xFF197A83)
                  : const Color(0xFFD3E1E3),
              width: 2,
            ),
          ),
          child: icon == null
              ? null
              : Icon(
                  icon,
                  color: active
                      ? Colors.white
                      : const Color(0xFF60777B),
                  size: 28,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? const Color(0xFF17353B)
                        : const Color(0xFF60777B),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF60777B),
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

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 31,
        top: 4,
        bottom: 4,
      ),
      width: 3,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEFF1),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}