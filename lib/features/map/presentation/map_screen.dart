
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../domain/entities/map_risk.dart';
import 'providers/map_provider.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/risk_map_marker.dart';
import '../../risk/presentation/screens/risk_detail_screen.dart';


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

    Future.microtask(() {
      ref.read(mapControllerProvider.notifier).initialize();
    });
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 14);
  }

  void _openRiskDetails(MapRisk risk) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskDetailScreen(risk: risk),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);

    ref.listen<MapState>(
      mapControllerProvider,
      (previous, next) {
        if (next.error != null &&
            next.error != previous?.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
            ),
          );
        }
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: state.selectedLocation,
              initialZoom: 14,
              minZoom: 4,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.namegmail.urban_resilience',
              ),

              // Position de l'utilisateur
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
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
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

              // Risques
              MarkerLayer(
                markers: state.risks.map((risk) {
                  return Marker(
                    point: risk.position,
                    width: 50,
                    height: 50,
                    child: RiskMapMarker(
                      risk: risk,
                      onTap: () => _openRiskDetails(risk),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Barre de recherche
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MapSearchBar(
                onLocationSelected: (location) async {
                  _moveToLocation(location);
                },
              ),
            ),
          ),

          // Boutons flottants
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'location_button',
                  onPressed: () {
                    final location = state.currentLocation;

                    if (location != null) {
                      _moveToLocation(location);
                    } else {
                      ref
                          .read(mapControllerProvider.notifier)
                          .initialize();
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),

                const SizedBox(height: 12),

                FloatingActionButton(
                  heroTag: 'refresh_button',
                  onPressed: () {
                    ref
                        .read(mapControllerProvider.notifier)
                        .loadRisks(
                          state.selectedLocation,
                        );
                  },
                  child: state.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
