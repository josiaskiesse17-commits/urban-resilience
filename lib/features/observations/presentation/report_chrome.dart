import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';

class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/report');
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: SvgPicture.asset(
                  'assets/icons/risk-arrow-left.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faire un signalement',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aidez à informer votre zone',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportProgress extends StatelessWidget {
  final int step;
  final String label;

  const ReportProgress({super.key, required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Étape $step sur 4',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var index = 1; index <= 4; index++) ...[
                if (index > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= step
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ReportActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ReportActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.primary),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

enum CitizenNavTab { alertes, carte, profil, signaler }

class ReportNavigation extends StatelessWidget {
  const ReportNavigation({
    super.key,
    this.selected,
    this.isExpanded = true,
    this.onToggle,
  });

  /// Currently active tab; null when none of the three (e.g. report wizard).
  final CitizenNavTab? selected;
  /// Whether the navigation bar is in expanded state (showing all 4 items).
  final bool isExpanded;
  /// Callback to toggle between expanded and collapsed states.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isExpanded) {
      return CollapsedNavHandle(
        onTap: onToggle,
      );
    }

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x14000000),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _Item(
              label: 'Carte',
              asset: 'assets/icons/map-nav-map.svg',
              selected: selected == CitizenNavTab.carte,
              onTap: selected == CitizenNavTab.carte
                  ? null
                  : () => context.go('/map'),
            ),
          ),
          Expanded(
            child: _Item(
              label: 'Signaler',
              asset: 'assets/icons/map-nav-plus.svg',
              selected: selected == CitizenNavTab.signaler,
              onTap: selected == CitizenNavTab.signaler
                  ? null
                  : () => context.go('/report'),
            ),
          ),
          Expanded(
            child: _Item(
              label: 'Alertes',
              asset: 'assets/icons/map-nav-bell.svg',
              selected: selected == CitizenNavTab.alertes,
              onTap: selected == CitizenNavTab.alertes
                  ? null
                  : () => context.go('/alerts'),
            ),
          ),
          Expanded(
            child: _Item(
              label: 'Profil',
              asset: 'assets/icons/map-nav-user.svg',
              selected: selected == CitizenNavTab.profil,
              onTap: selected == CitizenNavTab.profil
                  ? null
                  : () => context.push('/profile'),
            ),
          ),
          _CollapseButton(
            scheme: scheme,
            isDark: isDark,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

class CollapsedNavHandle extends StatelessWidget {
  const CollapsedNavHandle({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 5,
        width: 120,
        decoration: BoxDecoration(
          color: AppPalette.primary,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.scheme,
    required this.isDark,
    this.onTap,
  });

  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 24,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  const _Item({
    required this.label,
    required this.asset,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = selected ? scheme.primary : scheme.onSurfaceVariant;
    final pillColor =
        selected ? scheme.primaryContainer : Colors.transparent;

  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: SvgPicture.asset(
            asset,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            height: 1.2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
  }
}
