import 'historical_distribution.dart';

class FloodHistoricalBaseline {
  final double rainfallBaselineMmPerHour;
  final double rainfallCriticalMmPerHour;

  final double rainfallAccumulation6hBaselineMm;
  final double rainfallAccumulation6hCriticalMm;

  final double riverDischargeBaselineM3s;
  final double riverDischargeCriticalM3s;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;
  final DateTime generatedAt;

  final int rainfallSampleCount;
  final int riverDischargeSampleCount;

  
  
  
  final HistoricalDistribution? rainfallHourlyDistribution;
  final HistoricalDistribution? rainfallSixHourDistribution;
  final HistoricalDistribution? riverDischargeDistribution;

  const FloodHistoricalBaseline({
    required this.rainfallBaselineMmPerHour,
    required this.rainfallCriticalMmPerHour,
    required this.rainfallAccumulation6hBaselineMm,
    required this.rainfallAccumulation6hCriticalMm,
    required this.riverDischargeBaselineM3s,
    required this.riverDischargeCriticalM3s,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    required this.generatedAt,
    required this.rainfallSampleCount,
    required this.riverDischargeSampleCount,
    this.rainfallHourlyDistribution,
    this.rainfallSixHourDistribution,
    this.riverDischargeDistribution,
  });

  Map<String, dynamic> toJson() {
    return {
      'rainfallBaselineMmPerHour':
          rainfallBaselineMmPerHour,
      'rainfallCriticalMmPerHour':
          rainfallCriticalMmPerHour,
      'rainfallAccumulation6hBaselineMm':
          rainfallAccumulation6hBaselineMm,
      'rainfallAccumulation6hCriticalMm':
          rainfallAccumulation6hCriticalMm,
      'riverDischargeBaselineM3s':
          riverDischargeBaselineM3s,
      'riverDischargeCriticalM3s':
          riverDischargeCriticalM3s,
      'referencePeriodStart':
          referencePeriodStart.toIso8601String(),
      'referencePeriodEnd':
          referencePeriodEnd.toIso8601String(),
      'generatedAt':
          generatedAt.toIso8601String(),
      'rainfallSampleCount':
          rainfallSampleCount,
      'riverDischargeSampleCount':
          riverDischargeSampleCount,
    };
  }
}