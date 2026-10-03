import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/observations/domain/observation.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input_exposure_enricher.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';

class FakeRiskExposureRepository implements RiskExposureRepository {
  FakeRiskExposureRepository({
    this.profile,
  });

  final FloodRiskExposureProfile? profile;

  @override
  Future<FloodRiskExposureProfile?> getProfile(
    String zoneId,
  ) async {
    if (profile?.zoneId == zoneId) {
      return profile;
    }

    return null;
  }

  @override
  Future<void> saveProfile(
    FloodRiskExposureProfile profile,
  ) async {}
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
    observationScore: 0,
    observationCount: 0,
    confirmedObservationCount: 0,
  );

  const profile = FloodRiskExposureProfile(
    zoneId: 'zone-1',
    populationExposureScore: 80,
    infrastructureExposureScore: 60,
    drainageVulnerabilityScore: 90,
    criticalFacilityExposureScore: 50,
    historicalFloodExposureScore: 75,
  );

  test(
    'combines exposure and citizen observations in RiskResult',
    () async {
      final repository = FakeRiskExposureRepository(
        profile: profile,
      );

      final exposureEnricher =
          FloodRiskInputExposureEnricher(
        repository: repository,
      );

      final service = RiskIntelligenceService(
        exposureEnricher: exposureEnricher,
      );

      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-1',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.confirmed,
          createdAt: now,
        ),
        Observation(
          id: 'obs-2',
          userId: 'user-2',
          latitude: 0,
          longitude: 0,
          type: ObservationType.blockedRoad,
          status: ObservationStatus.confirmed,
          createdAt: now,
        ),
      ];

      final result =
          await service.calculateFloodRiskWithExposureAndObservations(
        id: 'risk-1',
        zoneId: 'zone-1',
        locationName: 'Test Zone',
        latitude: 0,
        longitude: 0,
        input: input,
        observations: observations,
      );

      final vulnerability =
          result.evidence.measurements.firstWhere(
        (measurement) =>
            measurement.name == 'geographicVulnerability',
      );

      final historicalExposure =
          result.evidence.measurements.firstWhere(
        (measurement) =>
            measurement.name == 'historicalExposure',
      );

      expect(vulnerability.value, 71.5);
      expect(historicalExposure.value, 75);

      
      
      expect(
        result.evidence.measurements.map((measurement) => measurement.name),
        isNot(contains('citizenObservationRisk')),
      );

      expect(result.evidence.observationCount, 2);
      expect(
        result.evidence.confirmedObservationCount,
        2,
      );
    },
  );

  test(
    'pending observations are reflected in evidence but do not add risk',
    () async {
      final service = RiskIntelligenceService();

      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-1',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.pending,
          createdAt: now,
        ),
      ];

      final result =
          await service.calculateFloodRiskWithObservations(
        id: 'risk-2',
        locationName: 'Test Zone',
        latitude: 0,
        longitude: 0,
        input: input,
        observations: observations,
      );

      
      
      expect(
        result.evidence.measurements.map((measurement) => measurement.name),
        isNot(contains('citizenObservationRisk')),
      );

      expect(result.evidence.observationCount, 1);
      expect(
        result.evidence.confirmedObservationCount,
        0,
      );
    },
  );
}