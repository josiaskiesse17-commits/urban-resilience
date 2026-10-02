import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/zone_active_risk.dart';
import '../../../risk/presentation/hazard_presentation.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';

/// Opens the Zone Active Risks selection UI of a zone.
///
/// The sheet only reads what is stored: it never runs a risk pipeline. Every
/// row opens the Risk Details screen of one hazard (`/risk/{riskId}`), which is
/// the only place that generates or refreshes that hazard's assessment.
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

/// Zone Active Risks selection UI: the identified risks of a zone first, and
/// the hazards that carry no current risk afterwards so they stay reachable.
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
                0 => 'No active risk identified in this zone right now.',
                1 => '1 active risk identified in this zone.',
                final count => '$count active risks identified in this zone.',
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
          'Could not load the stored risks of ${zone.name}.',
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
          label: const Text('Retry'),
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
          _groupTitle(context, 'Active risks'),
          for (final assessment in identified) ...[
            _ZoneHazardTile(assessment: assessment),
            const SizedBox(height: 8),
          ],
        ],
        if (remaining.isNotEmpty) ...[
          const SizedBox(height: 8),
          _groupTitle(context, 'Other hazards'),
          for (final assessment in remaining) ...[
            _ZoneHazardTile(assessment: assessment),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 4),
        Text(
          'Assessments are generated and refreshed on the Risk Details '
          'screen of the selected hazard.',
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
              'No stored assessment identifies a risk in this zone. Open a '
              'hazard below to assess it: nothing is shown as a zero.',
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

/// One hazard of the zone: its icon, its name and the real state of its
/// stored assessment.
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
                      assessment.hazard.label,
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
          'Updated ${_formatDateTime(updatedAt)}';
    }

    return switch (assessment.status) {
      ZoneHazardStatus.identified => 'Stored assessment.',
      ZoneHazardStatus.notIdentified =>
        'A stored assessment exists but identifies no current risk.',
      ZoneHazardStatus.notAssessed =>
        'Nothing is stored yet: open it to generate the assessment.',
    };
  }

  static String _statusLabel(ZoneHazardAssessment assessment) {
    final level = assessment.riskLevel;

    if (level != null) {
      return level.name.toUpperCase();
    }

    return switch (assessment.status) {
      ZoneHazardStatus.identified => 'Assessed',
      ZoneHazardStatus.notIdentified => 'No risk',
      ZoneHazardStatus.notAssessed => 'Not assessed',
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

