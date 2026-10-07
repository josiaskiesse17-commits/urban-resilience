import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'navbar_state_provider.dart';

class RetractableBottomNavBar extends ConsumerWidget {
  const RetractableBottomNavBar({
    super.key,
    required this.selectedTab,
    this.onToggle,
  });

  final CitizenNavTab selectedTab;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: navbarState,
      builder: (context, child) {
        final isExpanded = navbarState.expanded;
        final toggle = onToggle ?? navbarState.toggle;

        if (!isExpanded) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: CollapsedNavHandle(
                onTap: toggle,
              ),
            ),
          );
        }

        return ReportNavigation(
          selected: selectedTab,
          isExpanded: true,
          onToggle: toggle,
        );
      },
    );
  }
}
