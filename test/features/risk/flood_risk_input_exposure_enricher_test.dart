import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input_exposure_enricher.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';

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

  test('applies stored exposure profile to input', () async {
    final repository = FakeRiskExposureRepository(profile: profile);

    final enricher = FloodRiskInputExposureEnricher(repository: repository);

    final result = await enricher.enrich(zoneId: 'zone-1', input: input);

    expect(result.vulnerabilityScore, 71.5);
    expect(result.historicalExposureScore, 75);

    expect(result.rainfallIntensityMmPerHour, input.rainfallIntensityMmPerHour);

    expect(result.riverDischargeM3s, input.riverDischargeM3s);

    expect(result.observationCount, input.observationCount);
  });

  test('keeps original input when profile does not exist', () async {
    final repository = FakeRiskExposureRepository();

    final enricher = FloodRiskInputExposureEnricher(repository: repository);

    final result = await enricher.enrich(zoneId: 'unknown-zone', input: input);

    expect(result.vulnerabilityScore, input.vulnerabilityScore);
    expect(result.historicalExposureScore, input.historicalExposureScore);

    expect(result.rainfallIntensityMmPerHour, input.rainfallIntensityMmPerHour);

    expect(result.riverDischargeM3s, input.riverDischargeM3s);
  });
}
