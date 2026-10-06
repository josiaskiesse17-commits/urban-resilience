import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/flood_environmental_data_source.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_baseline_service.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_data.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_data_source.dart';
import 'package:urban_resilience/features/risk/domain/live_flood_risk_service.dart';
import 'package:urban_resilience/features/risk/domain/risk_scenario.dart';

class _FakeFloodEnvironmentalDataSource
    implements FloodEnvironmentalDataSource {
  @override
  Future<FloodEnvironmentalData> fetch({
    required double latitude,
    required double longitude,
  }) async {
    return FloodEnvironmentalData(
      rainfallLastHourMm: 4,
      rainfallAccumulation6hMm: 14,
      riverDischargeM3s: 260,
      observedAt: DateTime.utc(2026, 9, 28, 8),
      rainfallSource: 'Fake Weather',
      riverSource: 'Fake River',
    );
  }
}

class _FakeHistoricalFloodDataSource implements HistoricalFloodDataSource {
  @override
  Future<HistoricalFloodData> fetch({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return HistoricalFloodData(
      hourlyRainfallValues: [0, 1, 2, 3, 4, 5, 6, 8],
      riverDischargeValues: [100, 120, 150, 180, 220, 300],
      referencePeriodStart: startDate,
      referencePeriodEnd: endDate,
      rainfallSource: 'Fake',
      riverSource: 'Fake',
    );
  }
}

LiveFloodRiskService _buildService({bool withBaselineService = true}) {
  return LiveFloodRiskService(
    dataSource: _FakeFloodEnvironmentalDataSource(),
    historicalBaselineService: withBaselineService
        ? HistoricalFloodBaselineService(
            dataSource: _FakeHistoricalFloodDataSource(),
          )
        : null,
  );
}

void main() {
  test('simulates a scenario on top of the live risk input', () async {
    final service = _buildService();

    final result = await service.simulateFloodScenario(
      id: 'zone-masina',
      locationName: 'Masina',
      latitude: -4.30,
      longitude: 15.35,
      startDate: DateTime.utc(2018, 1, 1),
      endDate: DateTime.utc(2022, 7, 31),
      scenario: const RiskScenario(
        name: 'Heavy rainfall',
        rainfallMultiplier: 1.5,
        rainfallAccumulationMultiplier: 1.5,
      ),
      vulnerabilityScore: 70,
      historicalExposureScore: 65,
      observationScore: 60,
      observationCount: 5,
      confirmedObservationCount: 3,
    );

    expect(result.baseline.locationName, 'Masina');

    expect(result.baseline.evidence.measurements.length, 6);

    expect(result.baseline.evidence.measurements.first.source, 'Fake Weather');

    expect(result.scenario.riskScore, greaterThan(result.baseline.riskScore));

    expect(result.scoreDifference, greaterThan(0));
  });

  test('requires the historical baseline service for scenarios', () async {
    final service = _buildService(withBaselineService: false);

    final future = service.simulateFloodScenario(
      id: 'zone-masina',
      locationName: 'Masina',
      latitude: -4.30,
      longitude: 15.35,
      startDate: DateTime.utc(2018, 1, 1),
      endDate: DateTime.utc(2022, 7, 31),
      scenario: const RiskScenario(
        name: 'Heavy rainfall',
        rainfallMultiplier: 1.5,
      ),
      vulnerabilityScore: 0,
      historicalExposureScore: 0,
      observationScore: 0,
      observationCount: 0,
      confirmedObservationCount: 0,
    );

    await expectLater(future, throwsA(isA<StateError>()));
  });
}
