import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../risk/domain/hazard_type.dart';
import '../domain/risk_alert.dart';
import 'alert_presentation.dart';
import 'providers/alert_providers.dart';






class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key, this.zoneId, this.hazardType});

  
  final String? zoneId;

  
  
  final String? hazardType;

  String? get _hazardLabel {
    final raw = hazardType;

    if (raw == null || raw.isEmpty) {
      return null;
    }

    return HazardType.fromId(raw)?.label ??
        HazardType.fromLabel(raw)?.label ??
        raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zone = zoneId;
    final hazard = _hazardLabel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: zone == null || hazard == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Sélectionnez un risque pour consulter ses alertes.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ref
                      .watch(alertsForContextProvider((
                        zoneId: zone,
                        hazardType: hazard,
                      )))
                      .when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => _ErrorView(error: error),
                        data: (alerts) => alerts.isEmpty
                            ? const Center(
                                child: Text('Aucune alerte pour ce risque.'),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: alerts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _AlertCard(alert: alerts[index]),
                              ),
                      ),
                ),
              ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final RiskAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = alertSeverityColor(alert.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alert.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    alertSeverityLabel(alert.severity),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(alert.message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              _formatDate(alert.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Les alertes ne sont pas disponibles pour le moment.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}