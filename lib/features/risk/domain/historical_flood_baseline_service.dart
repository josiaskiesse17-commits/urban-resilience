import 'flood_historical_baseline.dart';
import 'historical_flood_baseline_calculator.dart';
import 'historical_flood_data_source.dart';
import 'rainfall_window_calculator.dart';

class HistoricalFloodBaselineService {
  final HistoricalFloodDataSource dataSource;
  final HistoricalFloodBaselineCalculator baselineCalculator;
  final RainfallWindowCalculator rainfallWindowCalculator;

  const HistoricalFloodBaselineService({
    required this.dataSource,
    this.baselineCalculator = const HistoricalFloodBaselineCalculator(),
    this.rainfallWindowCalculator = const RainfallWindowCalculator(),
  });

  Future<FloodHistoricalBaseline> generate({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    final sixHourRainfall = rainfallWindowCalculator.rollingSixHourTotals(
      data.hourlyRainfallValues,
    );

    if (sixHourRainfall.isEmpty) {
      throw const FormatException(
        'Not enough historical rainfall data for six-hour windows.',
      );
    }

    return baselineCalculator.calculate(
      hourlyRainfallValues: data.hourlyRainfallValues,
      sixHourRainfallValues: sixHourRainfall,
      riverDischargeValues: data.riverDischargeValues,
      referencePeriodStart: data.referencePeriodStart,
      referencePeriodEnd: data.referencePeriodEnd,
    );
  }
}
