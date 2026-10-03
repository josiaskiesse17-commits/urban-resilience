import 'hazard_historical_data.dart';
import 'hazard_type.dart';


abstract interface class HazardHistoricalDataSource {
  Future<HazardHistoricalData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  });
}
