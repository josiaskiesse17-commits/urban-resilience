import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_risk_calculator.dart';
import 'package:urban_resilience/features/risk/domain/hazard_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/hazard_variable.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';

HazardVariable _variable({
  required String name,
  required double weight,
  required double value,
  double? referenceValue,
  double? statisticalCriticalValue,
  bool inverted = false,
}) {
  return HazardVariable(
    name: name,
    label: name,
    value: value,
    unit: 'u',
    measurementPeriod: 'instant',
    weight: weight,
    referenceValue: referenceValue,
    statisticalCriticalValue: statisticalCriticalValue,
    inverted: inverted,
  );
}

void main() {
  const calculator = HazardRiskCalculator();

  test('redistributes the factor weights over the available factors', () {
    final input = HazardRiskInput(
      hazard: HazardType.heat,
      primaryFactorLabel: 'Heat',
      variables: <HazardVariable>[
        _variable(
          name: 'hot',
          weight: 0.5,
          value: 100,
          referenceValue: 10,
          statisticalCriticalValue: 100,
        ),
        _variable(
          name: 'mild',
          weight: 0.3,
          value: 5,
          referenceValue: 10,
          statisticalCriticalValue: 100,
        ),
        _variable(name: 'noReference', weight: 0.2, value: 7),
      ],
      vulnerabilityScore: 80,
    );

    final assessment = calculator.calculate(input);

    expect(assessment.hazardScore, closeTo(62.5, 0.001));
    expect(assessment.hazardAvailable, isTrue);
    expect(assessment.excludedWeight, closeTo(0.2, 0.0001));

    expect(assessment.factorWeights, <String, double>{
      'hazard': 0.40,
      'vulnerability': 0.25,
      'currentObservations': 0.20,
    });

    expect(assessment.overallScore, closeTo(52.9412, 0.001));
    expect(assessment.riskLevel, RiskLevel.high);

    expect(assessment.variableScores, hasLength(3));
    expect(
      assessment.variableScores
          .where((item) => item.usedInScore)
          .map((item) => item.name),
      <String>['hot', 'mild'],
    );

    expect(assessment.factors.primaryFactorLabel, 'Heat');
    expect(assessment.factors.geographicVulnerability, 80);
    expect(assessment.factors.historicalExposure, 0);
    expect(assessment.factors.currentObservations, 0);
  });

  test('no available factor at all yields a zero score', () {
    final assessment = calculator.calculate(
      HazardRiskInput(
        hazard: HazardType.landslide,
        primaryFactorLabel: 'Rainfall (24 h)',
        variables: const <HazardVariable>[],
      ),
    );

    expect(assessment.hazardAvailable, isFalse);
    expect(assessment.overallScore, 0);
    expect(assessment.riskLevel, RiskLevel.low);
    expect(assessment.factorWeights, <String, double>{
      'currentObservations': 0.20,
    });
  });
}
