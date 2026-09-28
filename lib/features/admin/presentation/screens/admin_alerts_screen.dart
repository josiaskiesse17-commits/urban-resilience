import 'package:flutter/material.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() =>
      _AdminAlertsScreenState();
}

class _AdminAlertsScreenState
    extends State<AdminAlertsScreen> {
  final List<_Alert> _alerts = [
    _Alert(
      title: 'High flood risk in N\'Djili',
      zone: 'N\'Djili',
      severity: 'Critical',
      active: true,
      time: '12 minutes ago',
    ),
    _Alert(
      title: 'Heavy rainfall affecting Masina',
      zone: 'Masina',
      severity: 'High',
      active: true,
      time: '28 minutes ago',
    ),
    _Alert(
      title: 'Flood risk returned to moderate',
      zone: 'Limete',
      severity: 'Moderate',
      active: false,
      time: 'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildCreateCard(context),
                const SizedBox(height: 20),
                _buildAlertsList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alert Management',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage alerts shown to application users.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Alert',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Alert title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: 'High',
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Moderate',
                  child: Text('Moderate'),
                ),
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'Critical',
                  child: Text('Critical'),
                ),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 14),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_alert),
              label: const Text('Create Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Alert History',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ..._alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    alert.active
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                  ),
                  title: Text(alert.title),
                  subtitle: Text(
                    '${alert.zone} • ${alert.time}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment:
                        WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(alert.severity),
                      ),
                      Switch(
                        value: alert.active,
                        onChanged: (_) {
                          setState(() {
                            alert.active = !alert.active;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Alert {
  final String title;
  final String zone;
  final String severity;
  final String time;
  bool active;

  _Alert({
    required this.title,
    required this.zone,
    required this.severity,
    required this.active,
    required this.time,
  });
}