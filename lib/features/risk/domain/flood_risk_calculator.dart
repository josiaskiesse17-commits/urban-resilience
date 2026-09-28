import 'flood_risk_input.dart';
import 'risk_factors.dart';
import 'risk_score_utils.dart';
import 'risk_zone.dart';

class FloodRiskCalculation {
  final double rainfallScore;
  final double rainfallAccumulationScore;
  final double riverDischargeScore;
  final double hazardScore;
  final double overallScore;
  final RiskLevel riskLevel;
  final RiskFactors factors;

  const FloodRiskCalculation({
    required this.rainfallScore,
    required this.rainfallAccumulationScore,
    required this.riverDischargeScore,
    required this.hazardScore,
    required this.overallScore,
    required this.riskLevel,
    required this.factors,
  });
}

class FloodRiskCalculator {
  const FloodRiskCalculator();

  FloodRiskCalculation calculate(
    FloodRiskInput input,
  ) {
    final rainfallScore = RiskScoreUtils.linearScore(
      value: input.rainfallIntensityMmPerHour,
      baseline: input.rainfallBaselineMmPerHour,
      critical: input.rainfallCriticalMmPerHour,
    );

    final rainfallAccumulationScore =
        RiskScoreUtils.linearScore(
      value: input.rainfallAccumulation6hMm,
      baseline:
          input.rainfallAccumulation6hBaselineMm,
      critical:
          input.rainfallAccumulation6hCriticalMm,
    );

    final riverDischargeScore =
        RiskScoreUtils.linearScore(
      value: input.riverDischargeM3s,
      baseline:
          input.riverDischargeBaselineM3s,
      critical:
          input.riverDischargeCriticalM3s,
    );

    final hazardScore =
        RiskScoreUtils.weightedAverage([
      (
        value: rainfallScore,
        weight: 0.40,
      ),
      (
        value: rainfallAccumulationScore,
        weight: 0.30,
      ),
      (
        value: riverDischargeScore,
        weight: 0.30,
      ),
    ]);

    final vulnerability =
        RiskScoreUtils.clamp(
      input.vulnerabilityScore,
    );

    final historicalExposure =
        RiskScoreUtils.clamp(
      input.historicalExposureScore,
    );

    final observations =
        RiskScoreUtils.clamp(
      input.observationScore,
    );

    final overallScore =
        RiskScoreUtils.weightedAverage([
      (
        value: hazardScore,
        weight: 0.40,
      ),
      (
        value: vulnerability,
        weight: 0.25,
      ),
      (
        value: historicalExposure,
        weight: 0.15,
      ),
      (
        value: observations,
        weight: 0.20,
      ),
    ]);

    final riskLevel =
        RiskScoreUtils.riskLevelFromScore(
      overallScore,
    );

    final factors = RiskFactors(
      rainfall: rainfallScore,
      geographicVulnerability: vulnerability,
      historicalExposure: historicalExposure,
      currentObservations: observations,
    );

    return FloodRiskCalculation(
      rainfallScore: rainfallScore,
      rainfallAccumulationScore:
          rainfallAccumulationScore,
      riverDischargeScore:
          riverDischargeScore,
      hazardScore: hazardScore,
      overallScore: overallScore,
      riskLevel: riskLevel,
      factors: factors,
    );
  }
}