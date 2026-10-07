import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../risk/data/risk_repository.dart';
import '../../risk/presentation/providers/risk_live_providers.dart';
import '../../observations/presentation/report_chrome.dart';
import 'providers/map_provider.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/zone_active_risks_sheet.dart';
import 'widgets/zone_map_marker.dart';
import '../../../core/widgets/scaffold_with_nav_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(mapControllerProvider.notifier).initialize();
    });
  }

  void _moveTo(LatLng location) {
    _mapController.move(location, 14);
  }

  void _openZone(RiskZoneTarget zone) {
    showZoneActiveRisksSheet(context, zone);
  }

  void _recenter() {
    final location = ref.read(mapControllerProvider).currentLocation;

    if (location != null) {
      _moveTo(location);
      return;
    }

    ref.read(mapControllerProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final zones = ref.watch(riskZoneCatalogProvider);

    final currentLocationMarkers = state.currentLocation != null
        ? [
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
          ]
        : <Marker>[];

    final zoneMarkers = zones
        .map(
          (zone) => Marker(
            point: LatLng(zone.latitude, zone.longitude),
            width: 120,
            height: 62,
            alignment: const Alignment(0, 1 - 26 / 62),
            child: ZoneMapMarker(zone: zone, onTap: () => _openZone(zone)),
          ),
        )
        .toList();

    ref.listen<MapState>(mapControllerProvider, (previous, next) {
      final error = next.error;

      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    });

    final mapBody = Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: state.selectedLocation,
            initialZoom: 13,
            minZoom: 4,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.namegmail.urban_resilience',
            ),
            MarkerLayer(markers: currentLocationMarkers),
            MarkerLayer(markers: zoneMarkers),
          ],
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MapActionButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Retour',
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MapSearchBar(
                    onLocationSelected: (location) async {
                      _moveTo(location);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Keep the location control above the retractable navigation bar.
        Positioned(
          right: 16,
          bottom: 92,
          child: FloatingActionButton(
            heroTag: 'location_button',
            tooltip: 'Me localiser',
            onPressed: _recenter,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );

    return ScaffoldWithNavBar(selectedTab: CitizenNavTab.carte, body: mapBody);
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: IconButton(onPressed: onTap, tooltip: tooltip, icon: Icon(icon)),
    );
  }
}
