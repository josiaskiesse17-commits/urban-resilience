import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final mapControllerProvider = NotifierProvider<MapLocationController, MapState>(
  MapLocationController.new,
);

class MapState {
  final LatLng? currentLocation;
  final LatLng selectedLocation;
  final bool loading;
  final bool locationPermissionDenied;
  final String? error;

  const MapState({
    required this.currentLocation,
    required this.selectedLocation,
    required this.loading,
    required this.locationPermissionDenied,
    required this.error,
  });

  MapState copyWith({
    LatLng? currentLocation,
    LatLng? selectedLocation,
    bool? loading,
    bool? locationPermissionDenied,
    String? error,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      loading: loading ?? this.loading,
      locationPermissionDenied:
          locationPermissionDenied ?? this.locationPermissionDenied,
      error: error,
    );
  }
}

class MapLocationController extends Notifier<MapState> {
  static const LatLng defaultLocation = LatLng(-4.3276, 15.3142);

  @override
  MapState build() {
    return const MapState(
      currentLocation: null,
      selectedLocation: defaultLocation,
      loading: false,
      locationPermissionDenied: false,
      error: null,
    );
  }

  Future<void> initialize() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        state = state.copyWith(
          loading: false,
          locationPermissionDenied: true,
          error: 'La localisation est désactivée.',
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          locationPermissionDenied: true,
          error: 'Autorisation de localisation refusée.',
        );

        return;
      }

      final position = await Geolocator.getCurrentPosition();

      state = state.copyWith(
        currentLocation: LatLng(position.latitude, position.longitude),
        selectedLocation: LatLng(position.latitude, position.longitude),
        loading: false,
        locationPermissionDenied: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        error: 'Impossible de récupérer la localisation.',
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

      state = state.copyWith(selectedLocation: location);

      return location;
    } catch (_) {
      state = state.copyWith(error: 'Lieu introuvable.');

      return null;
    }
  }
}
