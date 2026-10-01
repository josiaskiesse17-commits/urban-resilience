import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';

class RiskDetailsScreen extends ConsumerWidget {
  final String? riskId;

  const RiskDetailsScreen({
    super.key,
    this.riskId,
  });

  static const _cardShadow = BoxShadow(
    color: Color.fromRGBO(16, 42, 49, 0.08),
    blurRadius: 20,
    offset: Offset(0, 6),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(selectedPlaceProvider);
    final city = place?.label ?? 'Marseille';

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
                child: _Header(city: city),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: const [
                    _SummaryCard(),
                    SizedBox(height: 12),
                    _WhyCard(),
                    SizedBox(height: 12),
                    _AdviceCard(),
                    SizedBox(height: 12),
                    _UpdatesButton(),
                  ],
                ),
              ),
              const _RiskNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String city;

  const _Header({required this.city});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          _HeaderButton(
            asset: 'assets/icons/risk-arrow-left.svg',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/map');
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zone à risque',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vieux-Port • $city',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _HeaderButton(asset: 'assets/icons/risk-share.svg'),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.asset,
    this.onTap,
  });

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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          left: BorderSide(color: Color(0xFFD64A45), width: 4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFCE8E6),
              shape: BoxShape.circle,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '78 %',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD64A45),
                    height: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PROBABILITÉ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD64A45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HighRiskChip(),
                SizedBox(height: 8),
                Text(
                  'Inondation rapide',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aujourd’hui • 16 h–22 h',
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
    );
  }
}

class _HighRiskChip extends StatelessWidget {
  const _HighRiskChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD64A45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/risk-dot.svg', width: 8, height: 8),
          const SizedBox(width: 8),
          const Text(
            'Risque élevé',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD64A45),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.inputBorder),
        boxShadow: const [RiskDetailsScreen._cardShadow],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            asset: 'assets/icons/risk-cloud-wind.svg',
            title: 'Pourquoi ce niveau ?',
          ),
          SizedBox(height: 12),
          Text(
            'Les fortes pluies attendues sur un sol déjà saturé peuvent faire monter rapidement le niveau de l’Huveaune et surcharger les évacuations du secteur.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppPalette.textMuted,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _Metric(
                asset: 'assets/icons/risk-cloud-rain.svg',
                value: '42 mm',
                caption: 'Pluie / 3 h',
              ),
              SizedBox(width: 8),
              _Metric(
                asset: 'assets/icons/risk-droplets.svg',
                value: '92 %',
                caption: 'Sol saturé',
              ),
              SizedBox(width: 8),
              _Metric(
                asset: 'assets/icons/risk-wind.svg',
                value: '58 km/h',
                caption: 'Rafales',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.inputBorder),
        boxShadow: const [RiskDetailsScreen._cardShadow],
      ),
      child: const Column(
        children: [
          _SectionTitle(
            asset: 'assets/icons/risk-shield.svg',
            title: 'Gestes recommandés',
          ),
          SizedBox(height: 12),
          _AdviceRow(
            asset: 'assets/icons/risk-route-off.svg',
            text: 'Évitez les quais et les passages souterrains.',
          ),
          SizedBox(height: 12),
          _AdviceRow(
            asset: 'assets/icons/risk-house.svg',
            text: 'Mettez vos biens essentiels en hauteur.',
          ),
          SizedBox(height: 12),
          _AdviceRow(
            asset: 'assets/icons/risk-radio.svg',
            text: 'Suivez les consignes de la mairie et des secours.',
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String asset;
  final String title;

  const _SectionTitle({
    required this.asset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(asset, width: 20, height: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppPalette.textDark,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String asset;
  final String value;
  final String caption;

  const _Metric({
    required this.asset,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SvgPicture.asset(asset, width: 17, height: 17),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppPalette.textDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceRow extends StatelessWidget {
  final String asset;
  final String text;

  const _AdviceRow({
    required this.asset,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppPalette.infoBoxBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(asset, width: 17, height: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppPalette.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdatesButton extends StatelessWidget {
  const _UpdatesButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppPalette.primary),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/risk-bell-plus.svg',
              width: 19,
              height: 19,
            ),
            const SizedBox(width: 8),
            const Text(
              'Recevoir les mises à jour',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskNavigation extends StatelessWidget {
  const _RiskNavigation();

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
            selected: true,
            onTap: () => context.go('/map'),
          ),
          _NavItem(
            label: 'Signaler',
            asset: 'assets/icons/map-nav-plus.svg',
            onTap: () => context.push('/report'),
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
