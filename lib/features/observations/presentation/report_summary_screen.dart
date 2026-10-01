import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';

class ReportSummaryScreen extends ConsumerWidget {
  const ReportSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(reportDraftProvider);

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              const SafeArea(bottom: false, child: ReportHeader()),
              const ReportProgress(step: 4, label: 'Récapitulatif'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    const Text(
                      'Vérifiez avant d’envoyer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Vous pouvez encore modifier les informations.',
                      style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppPalette.inputBorder),
                      ),
                      child: Column(
                        children: [
                          _Section(
                            title: 'Type de catastrophe',
                            onEdit: () => context.go('/report'),
                            child: Row(
                              children: [
                                SvgPicture.asset(draft.typeIcon, width: 20, height: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    draft.typeTitle,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 20, color: AppPalette.inputBorder),
                          _Section(
                            title: 'Description',
                            onEdit: () => context.go('/report/description'),
                            child: Text(
                              draft.description,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppPalette.textDark,
                              ),
                            ),
                          ),
                          const Divider(height: 20, color: AppPalette.inputBorder),
                          _Section(
                            title: 'Photo jointe',
                            onEdit: () => context.go('/report/description'),
                            child: draft.photoName == null
                                ? const Text(
                                    'Aucune photo',
                                    style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
                                  )
                                : Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/report-photo.svg',
                                        width: 52,
                                        height: 56,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          draft.photoName!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppPalette.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const Divider(height: 20, color: AppPalette.inputBorder),
                          _Section(
                            title: 'Lieu de l’événement',
                            onEdit: () => context.go('/report/location'),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/report-pin.svg',
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        draft.street,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppPalette.textDark,
                                        ),
                                      ),
                                      Text(
                                        draft.cityLine,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppPalette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.infoBoxBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Votre signalement sera vérifié par nos équipes avant toute publication.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppPalette.infoText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ReportActionButton(
                label: 'Envoyer le signalement',
                onPressed: () => context.go('/report/received'),
              ),
              const ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final Widget child;

  const _Section({
    required this.title,
    required this.onEdit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textDark,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: const Text(
                'Modifier',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
