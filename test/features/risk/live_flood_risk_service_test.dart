import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/flood_environmental_data_source.dart';
import 'package:urban_resilience/features/risk/domain/flood_historical_baseline.dart';
import 'package:urban_resilience/features/risk/domain/live_flood_risk_service.dart';

class _FakeFloodEnvironmentalDataSource
    implements FloodEnvironmentalDataSource {
  @override
  Future<FloodEnvironmentalData> fetch({
    required double latitude,
    required double longitude,
  }) async {
    return FloodEnvironmentalData(
      rainfallLastHourMm: 4.0,
      rainfallAccumulation6hMm: 11.0,
      riverDischargeM3s: 410.0,
      observedAt: DateTime.utc(2026, 9, 28, 8),
      rainfallSource: 'Fake Weather',
      riverSource: 'Fake River',
    );
  }
}

void main() {
  test('produces a RiskResult from live environmental data', () async {
    final service = LiveFloodRiskService(
      dataSource: _FakeFloodEnvironmentalDataSource(),
    );

    final result = await service.calculate(
      id: 'zone-masina',
      locationName: 'Masina',
      latitude: -4.30,
      longitude: 15.35,
      baseline: FloodHistoricalBaseline(
        rainfallBaselineMmPerHour: 1.5,
        rainfallCriticalMmPerHour: 8.0,
        rainfallAccumulation6hBaselineMm: 10.0,
        rainfallAccumulation6hCriticalMm: 45.0,
        riverDischargeBaselineM3s: 250.0,
        riverDischargeCriticalM3s: 600.0,
        referencePeriodStart: DateTime.utc(2018, 1, 1),
        referencePeriodEnd: DateTime.utc(2022, 7, 31),
        generatedAt: DateTime.utc(2026, 9, 28),
        rainfallSampleCount: 100000,
        riverDischargeSampleCount: 1600,
      ),
      vulnerabilityScore: 70,
      historicalExposureScore: 65,
      observationScore: 60,
      observationCount: 5,
      confirmedObservationCount: 3,
    );

    expect(result.locationName, 'Masina');

    expect(result.hazardType, 'Flooding');

    expect(result.riskScore, greaterThan(0));

    expect(result.riskScore, lessThanOrEqualTo(100));

    expect(result.evidence.measurements.length, 5);

    expect(result.evidence.measurements.first.source, 'Fake Weather');

    expect(
      result.evidence.measurements.any(
        (measurement) => measurement.name == 'citizenObservationRisk',
      ),
      isFalse,
    );
  });
}
