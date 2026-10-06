import 'flood_historical_baseline.dart';
import 'historical_flood_baseline_calculator.dart';
import 'historical_flood_data_source.dart';
import 'rainfall_window_calculator.dart';

class _CachedFloodBaseline {
  const _CachedFloodBaseline({required this.baseline, required this.cachedAt});

  final FloodHistoricalBaseline baseline;
  final DateTime cachedAt;
}

class HistoricalFloodBaselineService {
  final HistoricalFloodDataSource dataSource;
  final HistoricalFloodBaselineCalculator baselineCalculator;
  final RainfallWindowCalculator rainfallWindowCalculator;

  /// How long a generated baseline stays reusable. Historical baselines are
  /// computed from a fixed reference period, so they are refreshed far less
  /// often than the live environmental data that is fetched on every risk
  /// calculation.
  final Duration baselineMaxAge;

  HistoricalFloodBaselineService({
    required this.dataSource,
    this.baselineCalculator = const HistoricalFloodBaselineCalculator(),
    this.rainfallWindowCalculator = const RainfallWindowCalculator(),
    this.baselineMaxAge = const Duration(hours: 24),
  });

  final Map<String, _CachedFloodBaseline> _baselineCache =
      <String, _CachedFloodBaseline>{};

  Future<FloodHistoricalBaseline> generate({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final key =
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}|'
        '${startDate.toUtc().toIso8601String()}|'
        '${endDate.toUtc().toIso8601String()}';

    final cached = _baselineCache[key];

    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < baselineMaxAge) {
      return cached.baseline;
    }

    final data = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    final sixHourRainfall = rainfallWindowCalculator.rollingSixHourTotals(
      data.hourlyRainfallValues,
      times: data.hourlyRainfallTimes,
    );

    if (sixHourRainfall.isEmpty) {
      throw const FormatException(
        'Not enough historical rainfall data for six-hour windows.',
      );
    }

    final baseline = baselineCalculator.calculate(
      hourlyRainfallValues: data.hourlyRainfallValues,
      sixHourRainfallValues: sixHourRainfall,
      riverDischargeValues: data.riverDischargeValues,
      referencePeriodStart: data.referencePeriodStart,
      referencePeriodEnd: data.referencePeriodEnd,
    );

    _baselineCache[key] = _CachedFloodBaseline(
      baseline: baseline,
      cachedAt: DateTime.now(),
    );

    return baseline;
  }

  void clearBaselineCache() {
    _baselineCache.clear();
  }
}
