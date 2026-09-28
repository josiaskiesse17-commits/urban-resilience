import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
                      isWide,
                    ),
                    const SizedBox(height: 24),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildRiskOverview(context),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 2,
                            child: _buildSystemStatus(context),
                          ),
                        ],
                      )
                    else ...[
                      _buildRiskOverview(context),
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
          'System Overview',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor current risk conditions, citizen observations, alerts, and data health.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(
    BuildContext context,
    bool isWide,
  ) {
    final cards = [
      _MetricData(
        title: 'High-risk zones',
        value: '7',
        subtitle: '2 critical',
        icon: Icons.warning_amber_rounded,
      ),
      _MetricData(
        title: 'Pending reports',
        value: '14',
        subtitle: '5 new today',
        icon: Icons.assignment_outlined,
      ),
      _MetricData(
        title: 'Active alerts',
        value: '5',
        subtitle: '2 high priority',
        icon: Icons.notifications_outlined,
      ),
      _MetricData(
        title: 'Data sources',
        value: '8/9',
        subtitle: '1 source stale',
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
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600
            ? 2
            : 1,
        mainAxisExtent: 125,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        return _MetricCard(data: cards[index]);
      },
    );
  }

  Widget _buildRiskOverview(BuildContext context) {
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
                    'Current Risk Overview',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/admin/risk');
                  },
                  child: const Text('View risk intelligence'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _RiskRow(
              zone: 'Town',
              risk: 'HIGH',
              score: 77,
              color: Colors.orange,
            ),
            _RiskRow(
              zone: 'Town',
              risk: 'CRITICAL',
              score: 86,
              color: Colors.red,
            ),
            _RiskRow(
              zone: 'Town',
              risk: 'MODERATE',
              score: 48,
              color: Colors.amber,
            ),
            _RiskRow(
              zone: 'Town',
              risk: 'LOW',
              score: 22,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            const _SourceStatus(
              name: 'Weather API',
              status: 'Online',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'River data',
              status: 'Online',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'Historical data',
              status: 'Online',
              healthy: true,
            ),
            const _SourceStatus(
              name: 'Air quality',
              status: 'Stale',
              healthy: false,
            ),
            const SizedBox(height: 12),
            Text(
              'Last system update: 10:42',
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
                    'Recent Citizen Observations',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/admin/observations');
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.water),
              title: Text('Water accumulation reported'),
              subtitle: Text('Masina • 10 minutes ago'),
              trailing: Chip(
                label: Text('Pending'),
              ),
            ),
            const Divider(),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.block),
              title: Text('Road blocked by flooding'),
              subtitle: Text('N\'Djili • 18 minutes ago'),
              trailing: Chip(
                label: Text('Confirmed'),
              ),
            ),
          ],
        ),
      ),
    );
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