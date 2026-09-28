import 'flood_environmental_data.dart';

abstract interface class FloodEnvironmentalDataSource {
  Future<FloodEnvironmentalData> fetch({
    required double latitude,
    required double longitude,
  });
}