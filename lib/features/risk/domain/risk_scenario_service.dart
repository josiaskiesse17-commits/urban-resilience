import 'flood_historical_baseline.dart';
import 'flood_risk_input.dart';
import 'risk_intelligence_service.dart';
import 'risk_scenario.dart';
import 'risk_scenario_result.dart';

class RiskScenarioService {
  final RiskIntelligenceService _riskIntelligenceService;

  const RiskScenarioService({RiskIntelligenceService? riskIntelligenceService})
    : _riskIntelligenceService =
          riskIntelligenceService ?? const RiskIntelligenceService();

  RiskScenarioResult simulateFloodRisk({
    required RiskScenario scenario,
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodRiskInput baselineInput,
    String? rainfallSource,
    String? riverSource,
    DateTime? observedAt,
    FloodHistoricalBaseline? baseline,
  }) {
    final baselineResult = _riskIntelligenceService.calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: baselineInput,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
      baseline: baseline,
    );

    final scenarioInput = baselineInput.copyWith(
      rainfallIntensityMmPerHour:
          baselineInput.rainfallIntensityMmPerHour *
          scenario.rainfallMultiplier,
      rainfallAccumulation6hMm:
          baselineInput.rainfallAccumulation6hMm *
          scenario.rainfallAccumulationMultiplier,
      riverDischargeM3s:
          baselineInput.riverDischargeM3s + scenario.riverDischargeDeltaM3s,
      vulnerabilityScore: baselineInput.vulnerabilityScore != null
          ? baselineInput.vulnerabilityScore! + scenario.vulnerabilityDelta
          : null,
      observationScore:
          baselineInput.observationScore + scenario.observationScoreDelta,
      observationCount:
          baselineInput.observationCount + scenario.additionalObservationCount,
      confirmedObservationCount:
          baselineInput.confirmedObservationCount +
          scenario.additionalConfirmedObservationCount,
    );

    final scenarioResult = _riskIntelligenceService.calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: scenarioInput,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
      baseline: baseline,
    );

    return RiskScenarioResult(
      baseline: baselineResult,
      scenario: scenarioResult,
      scoreDifference: scenarioResult.riskScore - baselineResult.riskScore,
      riskLevelChanged: scenarioResult.riskLevel != baselineResult.riskLevel,
    );
  }
}
