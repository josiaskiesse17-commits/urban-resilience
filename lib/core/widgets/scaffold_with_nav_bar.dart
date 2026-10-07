import 'package:flutter/material.dart';

import 'navbar_state_provider.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.selectedTab,
    required this.body,
    this.floatingActionButton,
  });

  final CitizenNavTab selectedTab;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: body,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: navbarState,
              builder: (context, child) {
                if (!navbarState.expanded) {
                  return SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: CollapsedNavHandle(
                          onTap: navbarState.toggle,
                        ),
                      ),
                    ),
                  );
                }

                return SafeArea(
                  top: false,
                  child: ReportNavigation(
                    selected: selectedTab,
                    isExpanded: true,
                    onToggle: navbarState.toggle,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
