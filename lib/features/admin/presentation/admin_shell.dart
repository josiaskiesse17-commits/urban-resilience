import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({
    super.key,
    required this.child,
  });

  static const routes = [
    '/admin/dashboard',
    '/admin/risk',
    '/admin/observations',
    '/admin/alerts',
  ];

  static const labels = [
    'Dashboard',
    'Risk Intelligence',
    'Observations',
    'Alerts',
  ];

  static const icons = [
    Icons.dashboard_outlined,
    Icons.analytics_outlined,
    Icons.assignment_outlined,
    Icons.notifications_outlined,
  ];

  static const selectedIcons = [
    Icons.dashboard,
    Icons.analytics,
    Icons.assignment,
    Icons.notifications,
  ];

  int _currentIndex(String location) {
    final index = routes.indexOf(location);

    return index >= 0 ? index : 0;
  }

  void _navigate(
    BuildContext context,
    int index,
  ) {
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final location =
            GoRouterState.of(context).matchedLocation;

        final currentIndex = _currentIndex(location);

        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: _DesktopSidebar(
                    currentIndex: currentIndex,
                    onSelected: (index) {
                      _navigate(context, index);
                    },
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              _navigate(context, index);
            },
            destinations: [
              for (int i = 0; i < labels.length; i++)
                NavigationDestination(
                  icon: Icon(icons[i]),
                  selectedIcon: Icon(
                    selectedIcons[i],
                  ),
                  label: labels[i],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              24,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Urban Resilience',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onSelected,
              extended: true,
              minExtendedWidth: 250,
              destinations: [
                for (
                  int i = 0;
                  i < AdminShell.labels.length;
                  i++
                )
                  NavigationRailDestination(
                    icon: Icon(
                      AdminShell.icons[i],
                    ),
                    selectedIcon: Icon(
                      AdminShell.selectedIcons[i],
                    ),
                    label: Text(
                      AdminShell.labels[i],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}