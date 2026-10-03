import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';

class ReportReceivedScreen extends StatelessWidget {
  const ReportReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 104,
                          height: 104,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppPalette.infoBoxBg,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 72,
                            height: 72,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppPalette.primary,
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/report-check-large.svg',
                              width: 38,
                              height: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Merci, votre signalement est reçu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: AppPalette.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Il est en cours de vérification par nos équipes et les sources locales disponibles.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppPalette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppPalette.inputBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'VIG-2026-0942',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppPalette.inputBorder),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Suivi du signalement',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.textDark,
                                ),
                              ),
                              SizedBox(height: 16),
                              _Step(
                                title: 'Signalement transmis',
                                subtitle: 'Aujourd’hui à 17:42',
                                done: true,
                              ),
                              _Step(
                                title: 'Vérification en cours',
                                subtitle: 'Délai moyen : moins de 20 min',
                                active: true,
                              ),
                              _Step(
                                title: 'Décision et publication éventuelle',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppPalette.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/report-list.svg',
                              width: 19,
                              height: 19,
                            ),
                            label: const Text(
                              'Voir mes signalements',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppPalette.primary,
                              side: const BorderSide(
                                color: AppPalette.inputBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/report-map-icon.svg',
                              width: 19,
                              height: 19,
                            ),
                            label: const Text(
                              'Retour à la carte',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool done;
  final bool active;

  const _Step({
    required this.title,
    this.subtitle,
    this.done = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppPalette.primary
                  : active
                  ? AppPalette.infoBoxBg
                  : AppPalette.inputBorder,
              shape: BoxShape.circle,
            ),
            child: done
                ? SvgPicture.asset(
                    'assets/icons/report-check-small.svg',
                    width: 17,
                    height: 17,
                  )
                : active
                ? SvgPicture.asset(
                    'assets/icons/report-loader.svg',
                    width: 17,
                    height: 17,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: done || active
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: active ? AppPalette.primary : AppPalette.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
