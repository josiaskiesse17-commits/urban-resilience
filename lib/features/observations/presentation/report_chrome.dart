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
            color: Colors.white,
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
                  border: Border.all(color: AppPalette.inputBorder),
                ),
                child: SvgPicture.asset(
                  'assets/icons/risk-arrow-left.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Faire un signalement',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aidez à informer votre quartier',
                  style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
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

  const ReportProgress({
    super.key,
    required this.step,
    required this.label,
  });

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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.primary,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppPalette.textMuted),
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
                          ? AppPalette.primary
                          : AppPalette.inputBorder,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppPalette.primary),
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

class ReportNavigation extends StatelessWidget {
  const ReportNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppPalette.inputBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Item(
            label: 'Carte',
            asset: 'assets/icons/map-nav-map.svg',
            onTap: () => context.go('/map'),
          ),
          const _Item(
            label: 'Signaler',
            asset: 'assets/icons/map-nav-plus.svg',
            selected: true,
          ),
          _Item(
            label: 'Alertes',
            asset: 'assets/icons/map-nav-bell.svg',
            onTap: () => context.go('/alerts'),
          ),
          _Item(
            label: 'Profil',
            asset: 'assets/icons/map-nav-user.svg',
            onTap: () => context.push('/profile'),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppPalette.infoBoxBg : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: SvgPicture.asset(asset, width: 20, height: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppPalette.primary : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
