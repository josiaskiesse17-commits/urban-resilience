import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/map_repository.dart';
import '../../domain/entities/map_risk.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository();
});

final mapControllerProvider =
    NotifierProvider<MapController, MapState>(MapController.new);

class MapState {
  final LatLng? currentLocation;
  final LatLng selectedLocation;
  final List<MapRisk> risks;
  final bool loading;
  final bool locationPermissionDenied;
  final String? error;

  const MapState({
    required this.currentLocation,
    required this.selectedLocation,
    required this.risks,
    required this.loading,
    required this.locationPermissionDenied,
    required this.error,
  });

  MapState copyWith({
    LatLng? currentLocation,
    LatLng? selectedLocation,
    List<MapRisk>? risks,
    bool? loading,
    bool? locationPermissionDenied,
    String? error,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      risks: risks ?? this.risks,
      loading: loading ?? this.loading,
      locationPermissionDenied:
          locationPermissionDenied ?? this.locationPermissionDenied,
      error: error,
    );
  }
}

class MapController extends Notifier<MapState> {
  late final MapRepository _repository;

  // Abidjan comme position de secours.
  static const LatLng defaultLocation = LatLng(
    5.3599517,
    -4.0082563,
  );

  @override
  MapState build() {
    _repository = ref.read(mapRepositoryProvider);

    return const MapState(
      currentLocation: null,
      selectedLocation: defaultLocation,
      risks: [],
      loading: false,
      locationPermissionDenied: false,
      error: null,
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await loadRisks(defaultLocation);

        state = state.copyWith(
          loading: false,
          locationPermissionDenied: true,
          error: 'La localisation est désactivée.',
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await loadRisks(defaultLocation);

        state = state.copyWith(
          loading: false,
          locationPermissionDenied: true,
          error: 'Autorisation de localisation refusée.',
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        currentLocation: location,
        selectedLocation: location,
        loading: false,
        locationPermissionDenied: false,
      );

      await loadRisks(location);
    } catch (e) {
      await loadRisks(defaultLocation);

      state = state.copyWith(
        loading: false,
        error: 'Impossible de récupérer la localisation.',
      );
    }
  }

  Future<void> loadRisks(LatLng location) async {
    state = state.copyWith(
      selectedLocation: location,
      loading: true,
    );

    try {
      final risks = await _repository.getRisksAround(location);

      state = state.copyWith(
        selectedLocation: location,
        risks: risks,
        loading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Impossible de récupérer les risques.',
      );
    }
  }

  Future<LatLng?> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      return null;
    }

    try {
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        return null;
      }

      final location = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      await loadRisks(location);

      return location;
    } catch (e) {
      state = state.copyWith(
        error: 'Lieu introuvable.',
      );

      return null;
    }
  }
}