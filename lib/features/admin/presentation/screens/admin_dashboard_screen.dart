import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/risk_zone.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () {},
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildMetrics(
                      context,
                      ref,
                      isWide,
                    ),
                    const SizedBox(height: 24),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildRiskOverview(context, ref),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildSystemStatus(context),
                          ),
                        ],
                      )
                    else ...[
                      _buildRiskOverview(context, ref),
                      const SizedBox(height: 20),
                      _buildSystemStatus(context),
                    ],
                    const SizedBox(height: 24),
                    _buildRecentObservations(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vue d'ensemble du système",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Suivez les conditions de risque actuelles, les observations '
          'citoyennes, les alertes et la santé des données.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    WidgetRef ref,
    bool isWide,
  ) {
    final zones = ref.watch(riskZoneCatalogProvider);

    var assessed = 0;
    var highRisk = 0;
    var critical = 0;
    var loading = 0;

    for (final zone in zones) {
      final riskAsync = ref.watch(riskResultProvider(zone.id));
      final result = riskAsync.value;

      if (result == null) {
        if (riskAsync.isLoading) {
          loading++;
        }

        continue;
      }

      assessed++;

      if (result.riskLevel == RiskLevel.critical) {
        critical++;
        highRisk++;
      } else if (result.riskLevel == RiskLevel.high) {
        highRisk++;
      }
    }

    final cards = [
      _MetricData(
        title: 'Zones à risque élevé',
        value: loading > 0 && assessed == 0 ? '—' : '$highRisk',
        subtitle: loading > 0
            ? 'Chargement des évaluations de zones...'
            : assessed == 0
                ? 'Aucune évaluation enregistrée'
                : '$critical critique(s) • '
                    '$assessed sur ${zones.length} évaluées',
        icon: Icons.warning_amber_rounded,
      ),
      _MetricData(
        title: 'Signalements en attente',
        value: '14',
        subtitle: '5 nouveaux aujourd’hui',
        icon: Icons.assignment_outlined,
      ),
      _MetricData(
        title: 'Alertes actives',
        value: '5',
        subtitle: '2 de priorité élevée',
        icon: Icons.notifications_outlined,
      ),
      _MetricData(
        title: 'Sources de données',
        value: '8/9',
        subtitle: '1 source périmée',
        icon: Icons.cloud_outlined,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(
              child: _MetricCard(data: cards[i]),
            ),
            if (i != cards.length - 1)
              const SizedBox(width: 16),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 2 : 1,
        mainAxisExtent: 125,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return _MetricCard(data: cards[index]);
      },
    );
  }

  Widget _buildRiskOverview(
    BuildContext context,
    WidgetRef ref,
  ) {
    final zones = ref.watch(riskZoneCatalogProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vue d’ensemble des risques actuels',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/admin/risk');
                  },
                  child: const Text('Voir l’intelligence des risques'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (zones.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Aucune zone de risque disponible'),
                subtitle: Text(
                  'Aucune zone de risque configurée n’a été trouvée.',
                ),
              )
            else
              for (final zone in zones) ...[
                _zoneRiskRow(context, ref, zone),
              ],
          ],
        ),
      ),
    );
  }

  Widget _zoneRiskRow(
    BuildContext context,
    WidgetRef ref,
    RiskZoneTarget zone,
  ) {
    final theme = Theme.of(context);
    final riskAsync = ref.watch(riskResultProvider(zone.id));
    final result = riskAsync.value;

    if (result == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(zone.name),
        subtitle: Text(
          riskAsync.isLoading
              ? 'Chargement de l’évaluation enregistrée...'
              : 'Aucune évaluation enregistrée. Ouvrez l’intelligence '
                  'des risques pour la générer.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '—',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return _RiskRow(
      zone: zone.name,
      risk: _riskLevelLabel(result.riskLevel),
      score: result.riskScore.round(),
      color: _riskColor(context, result.riskLevel),
    );
  }

  static String _riskLevelLabel(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => 'FAIBLE',
      RiskLevel.medium => 'MOYEN',
      RiskLevel.high => 'ÉLEVÉ',
      RiskLevel.critical => 'CRITIQUE',
    };
  }

  Widget _buildSystemStatus(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Santé des données',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            const _SourceStatus(
              name: 'API météo',
              status: 'En ligne',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'Données fluviales',
              status: 'En ligne',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'Données historiques',
              status: 'En ligne',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'Qualité de l’air',
              status: 'Périmée',
              healthy: false,
            ),
            const SizedBox(height: 12),
            Text(
              'Dernière mise à jour du système : 10:42',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentObservations(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Observations citoyennes récentes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/admin/observations');
                  },
                  child: const Text('Tout voir'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.water),
              title: Text('Accumulation d’eau signalée'),
              subtitle: Text('Masina • il y a 10 minutes'),
              trailing: Chip(
                label: Text('En attente'),
              ),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.block),
              title: Text('Route bloquée par une inondation'),
              subtitle: Text("N'Djili • il y a 18 minutes"),
              trailing: Chip(
                label: Text('Confirmée'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _riskColor(
  BuildContext context,
  RiskLevel level,
) {
  switch (level) {
    case RiskLevel.low:
      return Colors.green;

    case RiskLevel.medium:
      return Colors.amber.shade800;

    case RiskLevel.high:
      return Colors.orange;

    case RiskLevel.critical:
      return Theme.of(context).colorScheme.error;
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              child: Icon(data.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                  Text(
                    data.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String zone;
  final String risk;
  final int score;
  final Color color;

  const _RiskRow({
    required this.zone,
    required this.risk,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(zone),
      subtitle: LinearProgressIndicator(
        value: score / 100,
        color: color,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            risk,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('$score/100'),
        ],
      ),
    );
  }
}

class _SourceStatus extends StatelessWidget {
  final String name;
  final String status;
  final bool healthy;

  const _SourceStatus({
    required this.name,
    required this.status,
    required this.healthy,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        healthy ? Icons.check_circle : Icons.warning,
      ),
      title: Text(name),
      trailing: Text(status),
    );
  }
}