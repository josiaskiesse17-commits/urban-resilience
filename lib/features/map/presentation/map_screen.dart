import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/presentation/city_picker_sheet.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';
import 'package:urban_resilience/features/map/presentation/providers/map_provider.dart' as map_feature;

class MapScreen extends ConsumerStatefulWidget {
  static const _shadow = BoxShadow(
    color: Color.fromRGBO(16, 42, 49, 0.14),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapKey = GlobalKey<_LiveRiskMapState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_openProvidedMap);
  }

  Future<void> _openProvidedMap() async {
    final place = ref.read(selectedPlaceProvider);
    final map = ref.read(map_feature.mapControllerProvider.notifier);

    if (place == null) {
      await map.initialize();
      return;
    }

    await map.loadRisks(
      LatLng(place.latitude, place.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(selectedPlaceProvider);
    final placeLabel = place?.label ?? 'Gombe';

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _LiveRiskMap(key: _mapKey),
                    SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            right: 16,
                            top: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _PlaceCard(
                                    label: placeLabel,
                                    onTap: () async {
                                      final city = await showCityPicker(context);
                                      if (city == null) {
                                        return;
                                      }
                                      await ref
                                          .read(selectedPlaceProvider.notifier)
                                          .select(city);
                                      await ref
                                          .read(
                                            map_feature
                                                .mapControllerProvider
                                                .notifier,
                                          )
                                          .loadRisks(
                                            LatLng(
                                              city.latitude,
                                              city.longitude,
                                            ),
                                          );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const _RoundIconButton(
                                  size: 52,
                                  asset: 'assets/icons/map-layers.svg',
                                  iconSize: 21,
                                  shadow: MapScreen._shadow,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: 168,
                            child: _RoundIconButton(
                              size: 46,
                              asset: 'assets/icons/map-crosshair.svg',
                              iconSize: 21,
                              onPressed: () => _mapKey.currentState?.recenter(),
                              shadow: const BoxShadow(
                                color: Color.fromRGBO(16, 42, 49, 0.08),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: _RiskPreview(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const _MapNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [MapScreen._shadow],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/map-pin-place.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position détectée',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppPalette.textMuted,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textDark,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/icons/map-chevron-down.svg',
                width: 18,
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final double size;
  final String asset;
  final double iconSize;
  final BoxShadow shadow;
  final VoidCallback? onPressed;

  const _RoundIconButton({
    required this.size,
    required this.asset,
    required this.iconSize,
    required this.shadow,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [shadow],
          ),
          child: SvgPicture.asset(asset, width: iconSize, height: iconSize),
        ),
      ),
    );
  }
}

class _LiveRiskMap extends ConsumerStatefulWidget {
  const _LiveRiskMap({super.key});

  @override
  ConsumerState<_LiveRiskMap> createState() => _LiveRiskMapState();
}

class _LiveRiskMapState extends ConsumerState<_LiveRiskMap> {
  final MapController _controller = MapController();
  static const double _zoom = 14;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(map_feature.mapControllerProvider);

    ref.listen(map_feature.mapControllerProvider, (previous, next) {
      if (previous?.selectedLocation != next.selectedLocation) {
        _controller.move(next.selectedLocation, _zoom);
      }
    });

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: state.selectedLocation,
        initialZoom: _zoom,
        minZoom: 4,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.namegmail.urban_resilience',
        ),
        if (state.currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: state.currentLocation!,
                width: 45,
                height: 45,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap'),
          ],
        ),
      ],
    );
  }

  void recenter() {
    final state = ref.read(map_feature.mapControllerProvider);
    final location = state.currentLocation ?? state.selectedLocation;
    _controller.move(location, _zoom);
  }
}

class _RiskPreview extends StatelessWidget {
  const _RiskPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [MapScreen._shadow],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Niveaux de risque',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textDark,
                ),
              ),
              Spacer(),
              _LevelChip(
                label: 'Modéré',
                dot: 'assets/icons/map-dot-moderate.svg',
                borderColor: Color(0xFFE8A629),
                background: Colors.white,
                textColor: AppPalette.textDark,
              ),
              SizedBox(width: 8),
              _LevelChip(
                label: 'Élevé',
                dot: 'assets/icons/map-dot-high.svg',
                borderColor: Color(0xFFD64A45),
                background: Color(0xFFFCE8E6),
                textColor: Color(0xFFD64A45),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppPalette.inputBorder),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/risk'),
            child: Row(
            children: [
              _FloodIcon(),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Risque d’inondation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Vieux-Port • À 1,2 km',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/icons/map-chevron-right.svg',
                width: 20,
                height: 20,
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

class _FloodIcon extends StatelessWidget {
  const _FloodIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SvgPicture.asset(
        'assets/icons/map-waves-card.svg',
        width: 22,
        height: 22,
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final String dot;
  final Color borderColor;
  final Color background;
  final Color textColor;

  const _LevelChip({
    required this.label,
    required this.dot,
    required this.borderColor,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          SvgPicture.asset(dot, width: 8, height: 8),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNavigation extends StatelessWidget {
  const _MapNavigation();

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
          const _NavItem(
            label: 'Carte',
            asset: 'assets/icons/map-nav-map.svg',
            selected: true,
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
    final color = selected ? AppPalette.primary : AppPalette.textMuted;

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
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
