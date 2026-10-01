import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../risk/data/risk_repository.dart';
import '../../risk/domain/risk_result.dart';
import '../../risk/domain/risk_zone.dart';
import '../../risk/presentation/providers/risk_live_providers.dart';

/// Citizen entry point of the Risk Intelligence feature.
///
/// Lists the zone catalog with the stored assessment of each zone. Selecting
/// a zone pushes `/risk/{zoneId}`, where [RiskDetailsScreen] loads the saved
/// [RiskResult] and generates it when it is missing or out of date. This
/// screen therefore never blocks on the AI/engine pipeline itself.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(riskZoneCatalogProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood risk'),
        actions: [
          IconButton(
            tooltip: 'Profile and role',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Know your zone before the next rainfall.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each zone combines live environmental data, the '
                  'historical reference of the same location and the '
                  'stored community exposure profile into one assessment. '
                  'Open a zone to see its live flood risk, and use the '
                  'hazard selector there for landslide, drought, heat, '
                  'wildfire and storm.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _ZoneList(zones: zones),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneList extends ConsumerWidget {
  const _ZoneList({required this.zones});

  final List<RiskZoneTarget> zones;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (zones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No zones published yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Zones are defined in the shared zone catalog. Ask an '
                'administrator to publish the coverage list.',
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int index = 0; index < zones.length; index++) ...[
            _ZoneTile(zone: zones[index]),
            if (index < zones.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

/// A single zone row: shows the stored assessment (level, score, last
/// updated) and opens the risk details screen for that zone.
class _ZoneTile extends ConsumerWidget {
  const _ZoneTile({required this.zone});

  final RiskZoneTarget zone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final riskAsync = ref.watch(riskResultProvider(zone.id));
    final risk = riskAsync.value;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),
      leading: CircleAvatar(
        backgroundColor: risk == null
            ? theme.colorScheme.surfaceContainerHighest
            : _riskColor(context, risk.riskLevel)
                .withValues(alpha: 0.18),
        child: risk == null
            ? Icon(
                Icons.water_drop_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : Text(
                '${risk.riskScore.round()}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _riskColor(context, risk.riskLevel),
                ),
              ),
      ),
      title: Text(
        zone.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        switch (risk) {
          null =>
            riskAsync.isLoading
                ? 'Loading the saved assessment...'
                : 'Open the zone to generate its assessment.',
          final result =>
            '${_levelLabel(result.riskLevel)} risk  ·  '
            'Updated ${_formatDateTime(result.updatedAt)}',
        },
        style: theme.textTheme.bodySmall?.copyWith(
          color: risk == null
              ? theme.colorScheme.onSurfaceVariant
              : _riskColor(context, risk.riskLevel),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => context.go('/risk/${zone.id}'),
    );
  }
}

Color _riskColor(BuildContext context, RiskLevel level) {
  return switch (level) {
    RiskLevel.low => Colors.green,
    RiskLevel.medium => Colors.amber.shade700,
    RiskLevel.high => Colors.orange.shade800,
    RiskLevel.critical => Theme.of(context).colorScheme.error,
  };
}

String _levelLabel(RiskLevel level) {
  return switch (level) {
    RiskLevel.low => 'Low',
    RiskLevel.medium => 'Medium',
    RiskLevel.high => 'High',
    RiskLevel.critical => 'Critical',
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date = '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
  final time = '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
