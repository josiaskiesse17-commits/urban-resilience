import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';

class _ReportType {
  final String id;
  final String title;
  final String subtitle;
  final String icon;

  const _ReportType({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ReportCategory {
  final String label;
  final List<_ReportType> types;

  const _ReportCategory({required this.label, required this.types});
}

const _categories = [
  _ReportCategory(
    label: 'SISMES & VOLCANS',
    types: [
      _ReportType(
        id: 'earthquake',
        title: 'Séismes (tremblements de terre)',
        subtitle: 'Secousses, fissures, instabilité du sol',
        icon: 'assets/icons/report-waves.svg',
      ),
      _ReportType(
        id: 'volcano',
        title: 'Éruptions volcaniques',
        subtitle: 'Cendres, coulées, fumées et explosions',
        icon: 'assets/icons/report-mountain.svg',
      ),
    ],
  ),
  _ReportCategory(
    label: 'MER & TEMPESTES',
    types: [
      _ReportType(
        id: 'tsunami',
        title: 'Tsunamis',
        subtitle: 'Vagues exceptionnelles, submersion côtière',
        icon: 'assets/icons/report-waves-water.svg',
      ),
      _ReportType(
        id: 'landslide',
        title: 'Mouvements de terrain et avalanches',
        subtitle: 'Glissements, éboulements, coulées de neige',
        icon: 'assets/icons/report-mountain.svg',
      ),
      _ReportType(
        id: 'flood',
        title: 'Inondations',
        subtitle: 'Crues, débordements, eaux montantes',
        icon: 'assets/icons/report-waves-water.svg',
      ),
      _ReportType(
        id: 'marine',
        title: 'Submersions marines',
        subtitle: 'Tempêtes, surcotes, inondations côtières',
        icon: 'assets/icons/report-waves-water.svg',
      ),
      _ReportType(
        id: 'cyclone',
        title: 'Cyclones, ouragans et typhons',
        subtitle: 'Vents violents, pluies intenses, submersions',
        icon: 'assets/icons/report-wind.svg',
      ),
      _ReportType(
        id: 'tornado',
        title: 'Tornades',
        subtitle: 'Colonnes d’air violentes, dégâts localisés',
        icon: 'assets/icons/report-alert.svg',
      ),
    ],
  ),
  _ReportCategory(
    label: 'MÉTÉO EXTREME',
    types: [
      _ReportType(
        id: 'blizzard',
        title: 'Tempêtes de neige et blizzards',
        subtitle: 'Chutes abondantes, visibilité nulle, froid intense',
        icon: 'assets/icons/report-wind.svg',
      ),
      _ReportType(
        id: 'drought',
        title: 'Sécheresses',
        subtitle: 'Manque d’eau, sévère aridité, impacts sur l’environnement',
        icon: 'assets/icons/report-sun.svg',
      ),
      _ReportType(
        id: 'heatwave',
        title: 'Canicules',
        subtitle: 'Chaleur extrême, vagues de chaleur prolongées',
        icon: 'assets/icons/report-sun.svg',
      ),
    ],
  ),
  _ReportCategory(
    label: 'INCENDIES',
    types: [
      _ReportType(
        id: 'wildfire',
        title: 'Feux de forêt (incendies)',
        subtitle: 'Feux de végétation, fumées, propagation rapide',
        icon: 'assets/icons/report-flame.svg',
      ),
    ],
  ),
];

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({super.key});

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  String _selectedId = 'earthquake';

  @override
  Widget build(BuildContext context) {
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
                      _HeaderButton(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/map');
                          }
                        },
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
                              style: TextStyle(
                                fontSize: 13,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPalette.infoBoxBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/report-info.svg',
                            width: 18,
                            height: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En cas de danger immédiat, appelez le 112.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: AppPalette.infoText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppPalette.inputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choisissez un type de catastrophe',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppPalette.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Sélectionnez le phénomène principal pour mieux cadrer votre signalement.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.35,
                                        color: AppPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              _StepChip(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final category in _categories) ...[
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final type in category.types) ...[
                              _TypeRow(
                                type: type,
                                selected: type.id == _selectedId,
                                onTap: () =>
                                    setState(() => _selectedId = type.id),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final type = _categories
                          .expand((category) => category.types)
                          .firstWhere((item) => item.id == _selectedId);
                      ref
                          .read(reportDraftProvider.notifier)
                          .setType(title: type.title, icon: type.icon);
                      context.push('/report/description');
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppPalette.primary),
                      ),
                    ),
                    child: const Text(
                      'Continuer vers la description',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const _ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderButton({required this.onTap});

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
          child: SvgPicture.asset(
            'assets/icons/risk-arrow-left.svg',
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.infoBoxBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/report-dot.svg', width: 8, height: 8),
          SizedBox(width: 8),
          Text(
            'Étape 1',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppPalette.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final _ReportType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeRow({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.infoBoxBg : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppPalette.primary : AppPalette.inputBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppPalette.infoBoxBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SvgPicture.asset(type.icon, width: 20, height: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _SelectionMark(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  final bool selected;

  const _SelectionMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppPalette.primary : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppPalette.primary : AppPalette.inputBorder,
        ),
      ),
      child: selected
          ? SvgPicture.asset(
              'assets/icons/report-check.svg',
              width: 12,
              height: 12,
            )
          : null,
    );
  }
}

class _ReportNavigation extends StatelessWidget {
  const _ReportNavigation();

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
          _NavItem(
            label: 'Carte',
            asset: 'assets/icons/map-nav-map.svg',
            onTap: () => context.go('/map'),
          ),
          const _NavItem(
            label: 'Signaler',
            asset: 'assets/icons/map-nav-plus.svg',
            selected: true,
          ),
          _NavItem(
            label: 'Alertes',
            asset: 'assets/icons/map-nav-bell.svg',
            onTap: () => context.go('/alerts'),
          ),
          _NavItem(
            label: 'Profil',
            asset: 'assets/icons/map-nav-user.svg',
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
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
