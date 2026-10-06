import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';
import 'package:urban_resilience/features/observations/presentation/report_chrome.dart';
import 'package:urban_resilience/features/observations/presentation/report_draft.dart';
import 'package:urban_resilience/features/risk/data/risk_repository.dart';

class ReportLocationScreen extends ConsumerStatefulWidget {
  const ReportLocationScreen({super.key});

  @override
  ConsumerState<ReportLocationScreen> createState() =>
      _ReportLocationScreenState();
}

class _ReportLocationScreenState extends ConsumerState<ReportLocationScreen> {
  final _mapController = MapController();
  late final TextEditingController _street;
  late final TextEditingController _city;
  bool _editingAddress = false;

  @override
  void initState() {
    super.initState();
    final place = ref.read(selectedPlaceProvider);
    final draft = ref.read(reportDraftProvider);
    _street = TextEditingController(
      text: place == null ? draft.street : place.label,
    );
    _city = TextEditingController(
      text: place == null ? draft.cityLine : place.label,
    );
    if (place != null) {
      Future.microtask(() {
        ref
            .read(reportDraftProvider.notifier)
            .setPlace(
              street: place.label,
              cityLine: place.label,
              latitude: place.latitude,
              longitude: place.longitude,
            );
      });
    }
  }

  @override
  void dispose() {
    _street.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _useMyPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    final point = LatLng(position.latitude, position.longitude);
    _mapController.move(point, 15);
    ref
        .read(reportDraftProvider.notifier)
        .setPlace(
          street: 'Ma position',
          cityLine:
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          latitude: position.latitude,
          longitude: position.longitude,
        );
    _street.text = 'Ma position';
    _city.text =
        '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final mapLat = draft.latitude ?? RiskZoneCatalog.zones.first.latitude;
    final mapLng = draft.longitude ?? RiskZoneCatalog.zones.first.longitude;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              const SafeArea(bottom: false, child: ReportHeader()),
              const ReportProgress(step: 3, label: 'Localisation'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  children: [
                    const Text(
                      'Où se situe l’événement ?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Placez le repère au plus près du lieu observé.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 221,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(mapLat, mapLng),
                                initialZoom: 15,
                                onMapEvent: (event) {
                                  if (event is MapEventMoveEnd) {
                                    final center = event.camera.center;
                                    ref
                                        .read(reportDraftProvider.notifier)
                                        .setPlace(
                                          street: _street.text,
                                          cityLine: _city.text,
                                          latitude: center.latitude,
                                          longitude: center.longitude,
                                        );
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.namegmail.urban_resilience',
                                ),
                              ],
                            ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/map-pin-place.svg',
                                      width: 16,
                                      height: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      draft.cityLine,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppPalette.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.location_on,
                                color: AppPalette.primary,
                                size: 40,
                              ),
                            ),
                            const Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Déplacez la carte pour ajuster le repère',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppPalette.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppPalette.inputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adresse de l’événement',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_editingAddress)
                            Column(
                              children: [
                                TextField(controller: _street),
                                const SizedBox(height: 8),
                                TextField(controller: _city),
                              ],
                            )
                          else
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/report-pin.svg',
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _street.text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppPalette.textDark,
                                        ),
                                      ),
                                      Text(
                                        _city.text,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppPalette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(
                              () => _editingAddress = !_editingAddress,
                            ),
                            child: const Text(
                              'Corriger l’adresse',
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
                    OutlinedButton.icon(
                      onPressed: _useMyPosition,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: AppPalette.primary,
                        side: const BorderSide(color: AppPalette.inputBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/report-locate.svg',
                        width: 16,
                        height: 16,
                      ),
                      label: const Text(
                        'Utiliser ma position',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Votre position peut être différente du lieu de l’événement. Vérifiez le repère avant de continuer.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ReportActionButton(
                label: 'Continuer vers le récapitulatif',
                onPressed: () {
                  final latitude = draft.latitude ?? mapLat;
                  final longitude = draft.longitude ?? mapLng;
                  ref
                      .read(reportDraftProvider.notifier)
                      .setPlace(
                        street: _street.text.trim().isEmpty
                            ? 'Lieu sélectionné'
                            : _street.text.trim(),
                        cityLine: _city.text.trim().isEmpty
                            ? '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'
                            : _city.text.trim(),
                        latitude: latitude,
                        longitude: longitude,
                      );
                  context.push('/report/summary');
                },
              ),
              const ReportNavigation(),
            ],
          ),
        ),
      ),
    );
  }
}
