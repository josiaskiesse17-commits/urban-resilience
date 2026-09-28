import 'historical_flood_data.dart';

abstract interface class HistoricalFloodDataSource {
  Future<HistoricalFloodData> fetch({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  });
}