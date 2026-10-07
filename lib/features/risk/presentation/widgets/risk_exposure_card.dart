import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/flood_risk_exposure_profile.dart';
import '../../domain/hazard_type.dart';
import '../providers/risk_live_providers.dart';

class RiskExposureCard extends ConsumerWidget {
  final String zoneId;
  final HazardType hazardType;

  const RiskExposureCard({
    super.key,
    required this.zoneId,
    required this.hazardType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(riskExposureProfileProvider(zoneId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil d’exposition et vulnérabilité',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profil enregistré de risk_zones/$zoneId.',
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
              error: (error, _) => _buildMissing(context, '$error'),
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

  Widget _buildMissing(BuildContext context, String? error) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucun profil d’exposition n’est enregistré pour cette zone.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'La vulnérabilité géographique et l’exposition historique sont '
          'inconnues, et non nulles : le score ci-dessous ne les inclut '
          'pas.',
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

  Widget _buildProfile(BuildContext context, FloodRiskExposureProfile profile) {
    final theme = Theme.of(context);

    // Only display flood-specific metrics for Flooding hazard.
    // For Heat/Landslide, show a neutral state.
    final showFloodMetrics = hazardType == HazardType.flooding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFloodMetrics) ...[
          _ExposureBar(
            label: 'Exposition de la population',
            value: profile.populationExposureScore,
          ),
          _ExposureBar(
            label: 'Exposition des infrastructures',
            value: profile.infrastructureExposureScore,
          ),
          _ExposureBar(
            label: 'Vulnérabilité du drainage',
            value: profile.drainageVulnerabilityScore,
          ),
          _ExposureBar(
            label: 'Exposition des équipements critiques',
            value: profile.criticalFacilityExposureScore,
          ),
          _ExposureBar(
            label: 'Exposition historique aux inondations',
            value: profile.historicalFloodExposureScore,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Score de vulnérabilité',
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
            'Source : ${profile.source ?? 'non renseignée'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Mis à jour : '
            '${profile.updatedAt == null ? 'inconnu' : _formatDateTime(profile.updatedAt!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          const Text(
            'Aucune donnée d\'exposition n\'est disponible pour ce type de risque.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}

class _ExposureBar extends StatelessWidget {
  final String label;
  final double value;

  const _ExposureBar({required this.label, required this.value});

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
          LinearProgressIndicator(value: clamped / 100),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return '${local.year}-'
      '${twoDigits(local.month)}-'
      '${twoDigits(local.day)} '
      '${twoDigits(local.hour)}:'
      '${twoDigits(local.minute)}';
}
