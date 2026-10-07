import 'package:flutter/material.dart';

import 'navbar_state_provider.dart';
import 'package:urban_resilience/features/alerts/presentation/alerts_screen.dart';
import 'package:urban_resilience/features/auth/presentation/screens/profile_screen.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/signaler_hub_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.initialIndex,
  });

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: const [
              SignalerHubScreen(showNavBar: false),
              AlertsScreen(showNavBar: false),
              ProfileScreen(showNavBar: false),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _RetractableNavBar(
              currentIndex: _currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetractableNavBar extends StatelessWidget {
  const _RetractableNavBar({
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: navbarState,
      builder: (context, child) {
        if (!navbarState.expanded) {
          // IMPORTANT:
          // Give the collapsed navbar a finite height.
          // Without this constraint, the Positioned widget can
          // allow this widget to occupy the whole screen and
          // intercept touches.
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
            selected: _indexToTab(currentIndex),
            isExpanded: true,
            onToggle: navbarState.toggle,
          ),
        );
      },
    );
  }

  CitizenNavTab? _indexToTab(int index) {
    return switch (index) {
      0 => CitizenNavTab.signaler,
      1 => CitizenNavTab.alertes,
      2 => CitizenNavTab.profil,
      _ => null,
    };
  }
}
