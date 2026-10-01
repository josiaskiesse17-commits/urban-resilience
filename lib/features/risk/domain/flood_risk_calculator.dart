import 'flood_risk_input.dart';
import 'risk_factor_score.dart';
import 'risk_factors.dart';
import 'risk_measurement_label.dart';
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
      entries: _entries(
        rainfallScore: rainfallScore,
        rainfallAccumulationScore: rainfallAccumulationScore,
        riverDischargeScore: riverDischargeScore,
        vulnerability: vulnerability,
        historicalExposure: historicalExposure,
        observations: observations,
      ),
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

  /// Factors the flooding assessment really used, in display order: the
  /// weighted rainfall factor, the three environmental variables it is built
  /// from, then the exposure factors. The labels come from
  /// [RiskMeasurementLabel], so the Risk Factors row and the Evidence row of
  /// the same variable are worded identically.
  List<RiskFactorScore> _entries({
    required double rainfallScore,
    required double rainfallAccumulationScore,
    required double riverDischargeScore,
    required double vulnerability,
    required double historicalExposure,
    required double observations,
  }) {
    return <RiskFactorScore>[
      RiskFactorScore(
        name: 'hazard',
        label: 'Rainfall',
        score: RiskScoreUtils.weightedAverage([
          (value: rainfallScore, weight: 0.40),
          (value: rainfallAccumulationScore, weight: 0.30),
          (value: riverDischargeScore, weight: 0.30),
        ]),
        weight: 0.40,
        usedInScore: true,
        componentNames: const <String>[
          'rainfallIntensity',
          'rainfallAccumulation6h',
          'riverDischarge',
        ],
      ),
      RiskFactorScore(
        name: 'rainfallIntensity',
        label: RiskMeasurementLabel.of(
          name: 'rainfallIntensity',
          measurementPeriod: '1h',
        ),
        score: rainfallScore,
        weight: 0.40,
        usedInScore: true,
      ),
      RiskFactorScore(
        name: 'rainfallAccumulation6h',
        label: RiskMeasurementLabel.of(
          name: 'rainfallAccumulation6h',
        ),
        score: rainfallAccumulationScore,
        weight: 0.30,
        usedInScore: true,
      ),
      RiskFactorScore(
        name: 'riverDischarge',
        label: RiskMeasurementLabel.of(
          name: 'riverDischarge',
          measurementPeriod: 'daily',
        ),
        score: riverDischargeScore,
        weight: 0.30,
        usedInScore: true,
      ),
      RiskFactorScore(
        name: 'geographicVulnerability',
        label: 'Geographic vulnerability',
        score: vulnerability,
        weight: 0.25,
        usedInScore: true,
      ),
      RiskFactorScore(
        name: 'historicalExposure',
        label: 'Historical exposure',
        score: historicalExposure,
        weight: 0.15,
        usedInScore: true,
      ),
      RiskFactorScore(
        name: 'citizenObservationRisk',
        label: 'Citizen observations',
        score: observations,
        weight: 0.20,
        usedInScore: true,
      ),
    ];
  }
}