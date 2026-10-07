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

  FloodRiskCalculation calculate(FloodRiskInput input) {
    final rainfallScore = RiskScoreUtils.linearScore(
      value: input.rainfallIntensityMmPerHour,
      baseline: input.rainfallBaselineMmPerHour,
      critical: input.rainfallCriticalMmPerHour,
    );

    final rainfallAccumulationScore = RiskScoreUtils.linearScore(
      value: input.rainfallAccumulation6hMm,
      baseline: input.rainfallAccumulation6hBaselineMm,
      critical: input.rainfallAccumulation6hCriticalMm,
    );

    final riverDischargeScore = RiskScoreUtils.linearScore(
      value: input.riverDischargeM3s,
      baseline: input.riverDischargeBaselineM3s,
      critical: input.riverDischargeCriticalM3s,
    );

    final hazardScore = RiskScoreUtils.weightedAverage([
      (value: rainfallScore, weight: 0.40),
      (value: rainfallAccumulationScore, weight: 0.30),
      (value: riverDischargeScore, weight: 0.30),
    ]);

    final vulnerability = input.vulnerabilityScore != null
        ? RiskScoreUtils.clamp(input.vulnerabilityScore!)
        : null;

    final historicalExposure = input.historicalExposureScore != null
        ? RiskScoreUtils.clamp(input.historicalExposureScore!)
        : null;

    final observationScore = RiskScoreUtils.clamp(input.observationScore);

    final overallComponents = <({double value, double weight})>[];
    final factorWeights = <String, double>{};

    // Hazard is always available
    overallComponents.add((value: hazardScore, weight: 0.40));
    factorWeights['hazard'] = 0.40;

    if (vulnerability != null) {
      overallComponents.add((value: vulnerability, weight: 0.25));
      factorWeights['geographicVulnerability'] = 0.25;
    }

    if (historicalExposure != null) {
      overallComponents.add((value: historicalExposure, weight: 0.15));
      factorWeights['historicalExposure'] = 0.15;
    }

    overallComponents.add((value: observationScore, weight: 0.20));
    factorWeights['currentObservations'] = 0.20;

    final overallScore = RiskScoreUtils.weightedAverage(overallComponents);

    final riskLevel = RiskScoreUtils.riskLevelFromScore(overallScore);

    final factors = RiskFactors(
      rainfall: rainfallScore,
      geographicVulnerability: vulnerability,
      historicalExposure: historicalExposure,
      currentObservations: observationScore,
      entries: _entries(
        rainfallScore: rainfallScore,
        rainfallAccumulationScore: rainfallAccumulationScore,
        riverDischargeScore: riverDischargeScore,
        vulnerability: vulnerability,
        historicalExposure: historicalExposure,
        observationScore: observationScore,
      ),
    );

    return FloodRiskCalculation(
      rainfallScore: rainfallScore,
      rainfallAccumulationScore: rainfallAccumulationScore,
      riverDischargeScore: riverDischargeScore,
      hazardScore: hazardScore,
      overallScore: overallScore,
      riskLevel: riskLevel,
      factors: factors,
    );
  }

  List<RiskFactorScore> _entries({
    required double rainfallScore,
    required double rainfallAccumulationScore,
    required double riverDischargeScore,
    required double? vulnerability,
    required double? historicalExposure,
    required double observationScore,
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
        label: RiskMeasurementLabel.of(name: 'rainfallAccumulation6h'),
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
        label: RiskMeasurementLabel.of(name: 'geographicVulnerability'),
        score: vulnerability,
        weight: vulnerability == null ? 0 : 0.25,
        usedInScore: vulnerability != null,
        unavailableReason: vulnerability == null
            ? 'Aucun profil d\'exposition enregistré n\'a été trouvé pour cette zone. La vulnérabilité géographique est inconnue et exclue du score.'
            : null,
      ),
      RiskFactorScore(
        name: 'historicalExposure',
        label: RiskMeasurementLabel.of(name: 'historicalExposure'),
        score: historicalExposure,
        weight: historicalExposure == null ? 0 : 0.15,
        usedInScore: historicalExposure != null,
        unavailableReason: historicalExposure == null
            ? 'Aucun profil d\'exposition enregistré n\'a été trouvé pour cette zone. L\'exposition historique est inconnue et exclue du score.'
            : null,
      ),
      RiskFactorScore(
        name: 'currentObservations',
        label: RiskMeasurementLabel.of(name: 'currentObservations'),
        score: observationScore,
        weight: 0.20,
        usedInScore: true,
        unavailableReason: null,
      ),
    ];
  }
}