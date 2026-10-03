import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/risk_zone.dart';
import '../../../risk/domain/zone_active_risk.dart';
import '../../../risk/presentation/hazard_presentation.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';






void showZoneActiveRisksSheet(
  BuildContext context,
  RiskZoneTarget zone,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ZoneActiveRisksSheet(zone: zone),
  );
}



class ZoneActiveRisksSheet extends ConsumerWidget {
  const ZoneActiveRisksSheet({
    super.key,
    required this.zone,
  });

  final RiskZoneTarget zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final assessments = ref.watch(
      zoneHazardAssessmentsProvider(zone.id),
    );

    final identifiedCount = assessments.maybeWhen(
      data: (values) => values.where((value) => value.isIdentified).length,
      orElse: () => 0,
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              zone.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              switch (identifiedCount) {
                0 => 'Aucun risque actif identifié dans cette zone pour le '
                    'moment.',
                1 => '1 risque actif identifié dans cette zone.',
                final count => '$count risques actifs identifiés dans cette '
                    'zone.',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: assessments.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildError(
                  context,
                  ref,
                  error,
                ),
                data: (values) => _buildList(
                  context,
                  values,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    WidgetRef ref,
    Object error,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off),
        const SizedBox(height: 10),
        Text(
          'Impossible de charger les risques enregistrés de ${zone.name}.',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$error',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(
            zoneHazardAssessmentsProvider(zone.id),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<ZoneHazardAssessment> assessments,
  ) {
    final identified = assessments
        .where((assessment) => assessment.isIdentified)
        .toList();
    final remaining = assessments
        .where((assessment) => !assessment.isIdentified)
        .toList();

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        if (identified.isEmpty)
          _buildEmptyNotice(context)
        else ...[
          _groupTitle(context, 'Risques actifs'),
          for (final assessment in identified) ...[
            _ZoneHazardTile(assessment: assessment),
            const SizedBox(height: 8),
          ],
        ],
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: 8),
          _groupTitle(context, 'Autres risques'),
          for (final assessment in remaining) ...[
            _ZoneHazardTile(assessment: assessment),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 4),
        Text(
          'Les évaluations sont générées et actualisées sur la fiche de '
          'détail du risque sélectionné.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotice(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucune évaluation enregistrée n’identifie un risque dans '
              'cette zone. Ouvrez un risque ci-dessous pour l’évaluer : '
              'aucune valeur n’est affichée comme un zéro.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupTitle(
    BuildContext context,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}



class _ZoneHazardTile extends StatelessWidget {
  const _ZoneHazardTile({required this.assessment});

  final ZoneHazardAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = assessment.riskLevel;
    final color = level == null ? zoneNeutralColor : riskLevelColor(level);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/risk/${assessment.riskId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hazardIcon(assessment.hazard),
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assessment.hazard.labelFr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLine(assessment),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(
                label: _statusLabel(assessment),
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLine(ZoneHazardAssessment assessment) {
    final score = assessment.riskScore;
    final updatedAt = assessment.updatedAt;

    if (score != null && updatedAt != null) {
      return 'Score ${score.toStringAsFixed(0)}/100 • '
          'Mis à jour le ${_formatDateTime(updatedAt)}';
    }

    return switch (assessment.status) {
      ZoneHazardStatus.identified => 'Évaluation enregistrée.',
      ZoneHazardStatus.notIdentified =>
        'Une évaluation est enregistrée mais n’identifie aucun risque actuel.',
      ZoneHazardStatus.notAssessed =>
        'Aucune évaluation n’est encore enregistrée : ouvrez-la pour la '
            'générer.',
    };
  }

  static String _statusLabel(ZoneHazardAssessment assessment) {
    final level = assessment.riskLevel;

    if (level != null) {
      return _levelLabel(level);
    }

    return switch (assessment.status) {
      ZoneHazardStatus.identified => 'Évalué',
      ZoneHazardStatus.notIdentified => 'Aucun risque',
      ZoneHazardStatus.notAssessed => 'Non évalué',
    };
  }

  static String _levelLabel(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => 'FAIBLE',
      RiskLevel.medium => 'MOYEN',
      RiskLevel.high => 'ÉLEVÉ',
      RiskLevel.critical => 'CRITIQUE',
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();

  String twoDigits(int input) => input.toString().padLeft(2, '0');

  return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}

