import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input_exposure_enricher.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';

class FakeRiskExposureRepository implements RiskExposureRepository {
  FakeRiskExposureRepository({this.profile});

  final FloodRiskExposureProfile? profile;

  @override
  Future<FloodRiskExposureProfile?> getProfile(String zoneId) async {
    if (profile?.zoneId == zoneId) {
      return profile;
    }

    return null;
  }

  @override
  Future<void> saveProfile(FloodRiskExposureProfile profile) async {}
}

void main() {
  const input = FloodRiskInput(
    rainfallIntensityMmPerHour: 10,
    rainfallBaselineMmPerHour: 5,
    rainfallCriticalMmPerHour: 50,
    rainfallAccumulation6hMm: 30,
    rainfallAccumulation6hBaselineMm: 20,
    rainfallAccumulation6hCriticalMm: 100,
    riverDischargeM3s: 100,
    riverDischargeBaselineM3s: 80,
    riverDischargeCriticalM3s: 300,
    vulnerabilityScore: 10,
    historicalExposureScore: 20,
    observationScore: 40,
    observationCount: 2,
    confirmedObservationCount: 1,
  );

  const profile = FloodRiskExposureProfile(
    zoneId: 'zone-1',
    populationExposureScore: 80,
    infrastructureExposureScore: 60,
    drainageVulnerabilityScore: 90,
    criticalFacilityExposureScore: 50,
    historicalFloodExposureScore: 75,
  );

  test('uses stored exposure profile in final risk result', () async {
    final repository = FakeRiskExposureRepository(profile: profile);

    final enricher = FloodRiskInputExposureEnricher(repository: repository);

    final service = RiskIntelligenceService(exposureEnricher: enricher);

    final result = await service.calculateFloodRiskWithExposure(
      id: 'risk-1',
      zoneId: 'zone-1',
      locationName: 'Test Zone',
      latitude: -4.325,
      longitude: 15.322,
      input: input,
      rainfallSource: 'test',
      riverSource: 'test',
    );

    final vulnerabilityMeasurement = result.evidence.measurements.firstWhere(
      (measurement) => measurement.name == 'geographicVulnerability',
    );

    final historicalExposureMeasurement = result.evidence.measurements
        .firstWhere((measurement) => measurement.name == 'historicalExposure');

    expect(vulnerabilityMeasurement.value, 71.5);
    expect(historicalExposureMeasurement.value, 75);

    expect(result.id, 'risk-1');
    expect(result.locationName, 'Test Zone');
    expect(result.hazardType, 'Flooding');
  });

  test('keeps original risk inputs when no exposure profile exists', () async {
    final repository = FakeRiskExposureRepository();

    final enricher = FloodRiskInputExposureEnricher(repository: repository);

    final service = RiskIntelligenceService(exposureEnricher: enricher);

    final result = await service.calculateFloodRiskWithExposure(
      id: 'risk-2',
      zoneId: 'unknown-zone',
      locationName: 'Unknown Zone',
      latitude: -4.325,
      longitude: 15.322,
      input: input,
    );

    final vulnerabilityMeasurement = result.evidence.measurements.firstWhere(
      (measurement) => measurement.name == 'geographicVulnerability',
    );

    final historicalExposureMeasurement = result.evidence.measurements
        .firstWhere((measurement) => measurement.name == 'historicalExposure');

    expect(vulnerabilityMeasurement.value, 10);
    expect(historicalExposureMeasurement.value, 20);
  });
}
