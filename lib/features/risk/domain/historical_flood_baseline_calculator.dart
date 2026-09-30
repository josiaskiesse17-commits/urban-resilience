import 'flood_historical_baseline.dart';
import 'historical_statistics.dart';

class HistoricalFloodBaselineCalculator {
  const HistoricalFloodBaselineCalculator();

  FloodHistoricalBaseline calculate({
    required List<double> hourlyRainfallValues,
    required List<double> sixHourRainfallValues,
    required List<double> riverDischargeValues,
    required DateTime referencePeriodStart,
    required DateTime referencePeriodEnd,
    DateTime? generatedAt,
  }) {
    if (hourlyRainfallValues.isEmpty) {
      throw ArgumentError(
        'Hourly rainfall values cannot be empty.',
      );
    }

    if (sixHourRainfallValues.isEmpty) {
      throw ArgumentError(
        'Six-hour rainfall values cannot be empty.',
      );
    }

    if (riverDischargeValues.isEmpty) {
      throw ArgumentError(
        'River discharge values cannot be empty.',
      );
    }

    return FloodHistoricalBaseline(
      rainfallBaselineMmPerHour:
          HistoricalStatistics.median(
        hourlyRainfallValues,
      ),
      rainfallCriticalMmPerHour:
          HistoricalStatistics.percentile(
        hourlyRainfallValues,
        95,
      ),
      rainfallAccumulation6hBaselineMm:
          HistoricalStatistics.median(
        sixHourRainfallValues,
      ),
      rainfallAccumulation6hCriticalMm:
          HistoricalStatistics.percentile(
        sixHourRainfallValues,
        95,
      ),
      riverDischargeBaselineM3s:
          HistoricalStatistics.median(
        riverDischargeValues,
      ),
      riverDischargeCriticalM3s:
          HistoricalStatistics.percentile(
        riverDischargeValues,
        95,
      ),
      referencePeriodStart:
          referencePeriodStart,
      referencePeriodEnd:
          referencePeriodEnd,
      generatedAt:
          generatedAt ?? DateTime.now().toUtc(),
      rainfallSampleCount:
          hourlyRainfallValues.length,
      riverDischargeSampleCount:
          riverDischargeValues.length,
    );
  }
}