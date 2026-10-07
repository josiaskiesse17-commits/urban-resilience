import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/observations/domain/observation.dart';
import 'package:urban_resilience/features/risk/domain/flood_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/flood_environmental_data_source.dart';
import 'package:urban_resilience/features/risk/domain/flood_historical_baseline.dart';
import 'package:urban_resilience/features/risk/domain/live_flood_risk_service.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';

class _FakeFloodEnvironmentalDataSource
    implements FloodEnvironmentalDataSource {
  @override
  Future<FloodEnvironmentalData> fetch({
    required double latitude,
    required double longitude,
  }) async {
    return FloodEnvironmentalData(
      rainfallLastHourMm: 4,
      rainfallAccumulation6hMm: 11,
      riverDischargeM3s: 410,
      observedAt: DateTime.utc(2026, 9, 28, 8),
      rainfallSource: 'Fake Weather',
      riverSource: 'Fake River',
    );
  }
}

class _FakeRiskResultRepository implements RiskResultRepository {
  RiskResult? savedResult;

  @override
  Future<void> save(RiskResult result) async {
    savedResult = result;
  }

  @override
  Future<RiskResult?> get(String riskId) async {
    return savedResult?.id == riskId ? savedResult : null;
  }

  @override
  Future<RiskResult?> getLatestForZone(String zoneId) async {
    return savedResult;
  }
}

void main() {
  test('calculates and saves the integrated RiskResult', () async {
    final repository = _FakeRiskResultRepository();

    final service = LiveFloodRiskService(
      dataSource: _FakeFloodEnvironmentalDataSource(),
      riskIntelligenceService: const RiskIntelligenceService(),
      riskResultRepository: repository,
    );

    final result = await service.calculateWithExposureAndObservationsAndSave(
      id: 'zone-1',
      zoneId: 'zone-1',
      locationName: 'Test Zone',
      latitude: 0,
      longitude: 0,
      baseline: FloodHistoricalBaseline(
        rainfallBaselineMmPerHour: 1,
        rainfallCriticalMmPerHour: 8,
        rainfallAccumulation6hBaselineMm: 10,
        rainfallAccumulation6hCriticalMm: 45,
        riverDischargeBaselineM3s: 250,
        riverDischargeCriticalM3s: 600,
        referencePeriodStart: DateTime.utc(2018, 1, 1),
        referencePeriodEnd: DateTime.utc(2022, 7, 31),
        generatedAt: DateTime.utc(2026, 9, 28),
        rainfallSampleCount: 100,
        riverDischargeSampleCount: 100,
      ),
      observations: [
        Observation(
          id: 'observation-1',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.confirmed,
          createdAt: DateTime.now().toUtc(),
        ),
      ],
    );

    expect(result.id, 'zone-1');
    expect(repository.savedResult, isNotNull);
    expect(repository.savedResult!.id, 'zone-1');
    expect(repository.savedResult!.riskScore, greaterThan(0));
  });
}
