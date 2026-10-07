import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/features/observations/presentation/providers/observation_providers.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';
import 'package:urban_resilience/features/observations/presentation/report_type_mapping.dart';
import 'package:urban_resilience/features/risk/data/risk_repository.dart';

class ReportSummaryScreen extends ConsumerStatefulWidget {
  const ReportSummaryScreen({super.key});

  @override
  ConsumerState<ReportSummaryScreen> createState() =>
      _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends ConsumerState<ReportSummaryScreen> {
  bool _submitting = false;

  Future<void> _submit() async {
    if (_submitting) return;

    final draft = ref.read(reportDraftProvider);

    if (!draft.hasType || draft.description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez un type et une description avant d’envoyer.'),
        ),
      );
      return;
    }

    if (!draft.hasPlace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez le lieu de l’événement avant d’envoyer.'),
        ),
      );
      return;
    }

    final latitude = draft.latitude!;
    final longitude = draft.longitude!;
    final zoneId =
        draft.zoneId?.trim().isNotEmpty == true
            ? draft.zoneId!.trim()
            : RiskZoneCatalog.nearest(latitude, longitude).id;
    final hazardLabel = ReportTypeMapping.hazardLabel(
      draft.typeId,
      preferred: draft.hazardType,
    );
    final type = ReportTypeMapping.observationType(draft.typeId);

    setState(() => _submitting = true);

    try {
      final id = await ref
          .read(observationsRepositoryProvider)
          .createWithOptionalPhoto(
            zoneId: zoneId,
            hazardType: hazardLabel,
            latitude: latitude,
            longitude: longitude,
            type: type,
            description: draft.description,
            photoPath: draft.photoPath,
          );

      if (!mounted) return;

      ref.read(reportDraftProvider.notifier).setContext(
        zoneId: zoneId,
        hazardType: hazardLabel,
      );
      ref.read(reportDraftProvider.notifier).setSubmittedId(id);
      context.go('/report/received');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envoi impossible : $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    Text(
                      'Vérifiez avant d’envoyer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vous pouvez encore modifier les informations.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _Section(
            title: 'Type de catastrophe',
            onEdit: () => context.go('/report'),
child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    draft.typeIcon,
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    draft.typeTitle.isEmpty
                        ? 'Non renseigné'
                        : draft.typeTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
                          ),
                          Divider(
                            height: 20,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          _Section(
                            title: 'Description',
                            onEdit: () => context.go('/report/description'),
                            child: Text(
                              draft.description.isEmpty
                                  ? 'Aucune description'
                                  : draft.description,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Divider(
                            height: 20,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          _Section(
                            title: 'Photo jointe',
                            onEdit: () => context.go('/report/description'),
                            child: draft.photoName == null
                                ? Text(
                                    'Aucune photo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
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
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
),
                          Divider(
                            height: 20,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                         draft.street.isEmpty
                                             ? 'Lieu sélectionné'
                                             : draft.street,
                                       style: TextStyle(
                                         fontSize: 13,
                                         fontWeight: FontWeight.w600,
                                         color: Theme.of(context).colorScheme.onSurface,
                                       ),
                                     ),
                                     Text(
                                       draft.cityLine.isEmpty
                                           ? (draft.hasPlace
                                                 ? '${draft.latitude!.toStringAsFixed(4)}, ${draft.longitude!.toStringAsFixed(4)}'
                                                 : 'Non renseigné')
                                           : draft.cityLine,
                                       style: TextStyle(
                                         fontSize: 13,
                                         color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                          'Votre signalement sera vérifié par nos équipes avant toute publication.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              ReportActionButton(
                label: _submitting
                    ? 'Envoi en cours…'
                    : 'Envoyer le signalement',
                onPressed: _submitting ? () {} : _submit,
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Text(
                'Modifier',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
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
