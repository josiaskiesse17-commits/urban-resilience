import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/flood_risk_exposure_profile.dart';
import '../providers/risk_live_providers.dart';

/// Shows the stored exposure / vulnerability profile of a zone.
///
/// The citizen risk details screen and the admin risk screen both use this
/// card so they display the same `risk_zones/{zoneId}` data. When the zone has
/// no exposure document the card says so explicitly: missing exposure data
/// must never be read as "no vulnerability".
class RiskExposureCard extends ConsumerWidget {
  final String zoneId;

  const RiskExposureCard({
    super.key,
    required this.zoneId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync =
        ref.watch(riskExposureProfileProvider(zoneId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exposure & Vulnerability',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stored profile of risk_zones/$zoneId.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            profileAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _buildMissing(
                context,
                '$error',
              ),
              data: (profile) {
                if (profile == null) {
                  return _buildMissing(context, null);
                }

                return _buildProfile(context, profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissing(
    BuildContext context,
    String? error,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No exposure profile is stored for this zone.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Geographic vulnerability and historical exposure are '
          'unknown, not zero: the score below does not include them. '
          'An administrator has to add the exposure profile of '
          'risk_zones/$zoneId before the assessment is complete.',
          style: theme.textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            'The exposure profile could not be read: $error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfile(
    BuildContext context,
    FloodRiskExposureProfile profile,
  ) {
    final theme = Theme.of(context);
    final updatedAt = profile.updatedAt;
    final source = profile.source;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExposureBar(
          label: 'Population exposure',
          value: profile.populationExposureScore,
        ),
        _ExposureBar(
          label: 'Infrastructure exposure',
          value: profile.infrastructureExposureScore,
        ),
        _ExposureBar(
          label: 'Drainage vulnerability',
          value: profile.drainageVulnerabilityScore,
        ),
        _ExposureBar(
          label: 'Critical facility exposure',
          value: profile.criticalFacilityExposureScore,
        ),
        _ExposureBar(
          label: 'Historical flood exposure',
          value: profile.historicalFloodExposureScore,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                'Vulnerability score',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${profile.vulnerabilityScore.toStringAsFixed(0)}/100',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Source: ${source ?? 'not provided'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          'Updated: '
          '${updatedAt == null ? 'unknown' : _formatDateTime(updatedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ExposureBar extends StatelessWidget {
  final String label;
  final double value;

  const _ExposureBar({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${clamped.toStringAsFixed(0)}/100'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: clamped / 100,
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();

  String twoDigits(int value) =>
      value.toString().padLeft(2, '0');

  return '${local.year}-'
      '${twoDigits(local.month)}-'
      '${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:'
      '${twoDigits(local.minute)}';
}
