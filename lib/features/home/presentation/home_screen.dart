import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Citizen entry point of the Risk Intelligence feature.
///
/// The home screen deliberately does not list anything about risks: choosing a
/// zone happens on the map (`/map`), the identified risks of that zone are
/// listed by the Zone Active Risks selection UI, and the selected hazard opens
/// `/risk/{riskId}` ([RiskDetailsScreen]). That keeps a single entry point and
/// a single place - the Risk Details screen - where an assessment is generated
/// or refreshed.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<({IconData icon, String title, String detail})> _steps = [
    (
      icon: Icons.map_outlined,
      title: '1. Open the map',
      detail: 'Every zone is a coloured point: the colour is the highest '
          'risk currently identified in it.',
    ),
    (
      icon: Icons.list_alt_outlined,
      title: '2. Pick the zone',
      detail: 'The Zone Active Risks sheet lists the identified risks of the '
          'zone and the hazards that are not assessed yet.',
    ),
    (
      icon: Icons.insights_outlined,
      title: '3. Read the hazard',
      detail: 'The risk details screen shows the stored assessment, its '
          'evidence and the AI interpretation, and refreshes them there.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Each zone combines the live environmental data, the '
                  'historical reference of the same location and the stored '
                  'community exposure profile into one assessment. The map '
                  'shows where a risk is identified today.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/map'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open the map'),
                ),
                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: <Widget>[
                      for (int index = 0;
                          index < _steps.length;
                          index++) ...[
                        _StepTile(step: _steps[index]),
                        if (index < _steps.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

  final ({IconData icon, String title, String detail}) step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      leading: Icon(
        step.icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        step.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        step.detail,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
