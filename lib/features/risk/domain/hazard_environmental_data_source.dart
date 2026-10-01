import 'hazard_environmental_data.dart';
import 'hazard_type.dart';

/// Live environmental data of a hazard.
abstract interface class HazardEnvironmentalDataSource {
  Future<HazardLiveData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
  });
}
