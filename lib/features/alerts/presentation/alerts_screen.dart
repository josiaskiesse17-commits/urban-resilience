import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedPlaceProvider)?.label ?? 'Marseille';

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      _IconButton(
                        asset: 'assets/icons/risk-arrow-left.svg',
                        onTap: () => context.go('/map'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alertes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$city • 3 alertes actives',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const _IconButton(asset: 'assets/icons/alert-share.svg'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _Panel(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suivi des alertes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Les alertes sont classées par niveau de risque et récence pour vous aider à prioriser les actions.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppPalette.infoBoxBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              '3 actives',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Panel(
                      child: Column(
                        children: [
                          const _SectionTitle(
                            dot: 'assets/icons/alert-dot-red.svg',
                            title: 'Risque élevé',
                            count: '2 alertes',
                          ),
                          const SizedBox(height: 12),
                          _AlertCard(
                            background: const Color(0xFFFCE8E6),
                            border: const Color(0xFFD64A45),
                            icon: 'assets/icons/alert-waves.svg',
                            title: 'Risque d\'inondation élevé',
                            place: 'Vieux-Port et quais voisins',
                            time: 'Il y a 8 min',
                            status: 'En cours',
                            statusColor: const Color(0xFFD64A45),
                            onTap: () => context.push('/risk/zone-masina'),
                          ),
                          const SizedBox(height: 12),
                          _AlertCard(
                            background: const Color(0xFFFCE8E6),
                            border: const Color(0xFFD64A45),
                            icon: 'assets/icons/report-wind.svg',
                            title: 'Vents violents',
                            place: 'Secteur littoral et corniches',
                            time: 'Il y a 22 min',
                            status: 'En cours',
                            statusColor: const Color(0xFFD64A45),
                            onTap: () => context.push('/risk/zone-masina'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Panel(
                      child: Column(
                        children: [
                          const _SectionTitle(
                            dot: 'assets/icons/alert-dot-orange.svg',
                            title: 'Risque modéré',
                            count: '1 alerte',
                          ),
                          const SizedBox(height: 12),
                          _AlertCard(
                            background: const Color(0xFFFFF7E8),
                            border: const Color(0xFFE8A629),
                            icon: 'assets/icons/report-flame.svg',
                            title: 'Vigilance incendie',
                            place: 'Massif de l\'Étoile et zones boisées',
                            time: 'Il y a 1 h',
                            status: 'À surveiller',
                            statusColor: const Color(0xFFE8A629),
                            onTap: () => context.push('/risk/zone-masina'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Alertes récentes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppPalette.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Tout voir',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _RecentAlert(
                            icon: 'assets/icons/report-wind.svg',
                            title: 'Vents forts',
                            subtitle: 'Hier • Terminée',
                          ),
                          const SizedBox(height: 12),
                          _RecentAlert(
                            icon: 'assets/icons/report-flame.svg',
                            title: 'Vigilance incendie',
                            subtitle: '24 sept. • Terminée',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _AlertsNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.inputBorder),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String dot;
  final String title;
  final String count;

  const _SectionTitle({
    required this.dot,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(dot, width: 8, height: 8),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppPalette.textDark,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 11, color: AppPalette.textMuted),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Color background;
  final Color border;
  final String icon;
  final String title;
  final String place;
  final String time;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _AlertCard({
    required this.background,
    required this.border,
    required this.icon,
    required this.title,
    required this.place,
    required this.time,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset(icon, width: 22, height: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textDark,
                      ),
                    ),
                    Text(
                      place,
                      style: const TextStyle(fontSize: 13, color: AppPalette.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: const TextStyle(fontSize: 11, color: AppPalette.textMuted)),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              SvgPicture.asset('assets/icons/map-chevron-right.svg', width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAlert extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;

  const _RecentAlert({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, width: 18, height: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.textDark,
                  ),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppPalette.textMuted)),
              ],
            ),
          ),
          SvgPicture.asset('assets/icons/map-chevron-right.svg', width: 18, height: 18),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;

  const _IconButton({required this.asset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.inputBorder),
          ),
          child: SvgPicture.asset(asset, width: 20, height: 20),
        ),
      ),
    );
  }
}

class _AlertsNavigation extends StatelessWidget {
  const _AlertsNavigation();

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
          _Nav(label: 'Carte', asset: 'assets/icons/map-nav-map.svg', onTap: () => context.go('/map')),
          _Nav(label: 'Signaler', asset: 'assets/icons/map-nav-plus.svg', onTap: () => context.go('/report')),
          const _Nav(label: 'Alertes', asset: 'assets/icons/map-nav-bell.svg', selected: true),
          _Nav(label: 'Profil', asset: 'assets/icons/map-nav-user.svg', onTap: () => context.go('/profile')),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  const _Nav({
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
