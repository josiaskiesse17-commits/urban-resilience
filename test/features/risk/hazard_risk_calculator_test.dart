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

  test(
    'redistributes the factor weights over the available factors',
    () {
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
          _variable(
            name: 'noReference',
            weight: 0.2,
            value: 7,
          ),
        ],
        vulnerabilityScore: 80,
      );

      final assessment = calculator.calculate(input);

      // (100 * 0.5 + 0 * 0.3) / 0.8 = 62.5.
      expect(assessment.hazardScore, closeTo(62.5, 0.001));
      expect(assessment.hazardAvailable, isTrue);
      expect(assessment.excludedWeight, closeTo(0.2, 0.0001));

      expect(
        assessment.factorWeights,
        <String, double>{
          'hazard': 0.40,
          'vulnerability': 0.25,
        },
      );

      // (62.5 * 0.40 + 80 * 0.25) / 0.65.
      expect(
        assessment.overallScore,
        closeTo(69.2307, 0.001),
      );
      expect(assessment.riskLevel, RiskLevel.high);

      expect(assessment.variableScores, hasLength(3));
      expect(
        assessment.variableScores
            .where((item) => item.usedInScore)
            .map((item) => item.name),
        <String>['hot', 'mild'],
      );

      expect(
        assessment.factors.primaryFactorLabel,
        'Heat',
      );
      expect(
        assessment.factors.geographicVulnerability,
        80,
      );
      expect(assessment.factors.historicalExposure, 0);
      expect(assessment.factors.currentObservations, 0);
    },
  );

  test(
    'keeps observations out of the score until they are connected',
    () {
      final disconnected = calculator.calculate(
        HazardRiskInput(
          hazard: HazardType.drought,
          primaryFactorLabel: 'Rainfall deficit (30 d)',
          variables: <HazardVariable>[
            _variable(
              name: 'rain30d',
              weight: 1.0,
              value: 50,
              referenceValue: 10,
              statisticalCriticalValue: 100,
            ),
          ],
          vulnerabilityScore: 50,
        ),
      );

      expect(
        disconnected.factorWeights.containsKey('observations'),
        isFalse,
      );

      final connected = calculator.calculate(
        HazardRiskInput(
          hazard: HazardType.drought,
          primaryFactorLabel: 'Rainfall deficit (30 d)',
          variables: <HazardVariable>[
            _variable(
              name: 'rain30d',
              weight: 1.0,
              value: 50,
              referenceValue: 10,
              statisticalCriticalValue: 100,
            ),
          ],
          vulnerabilityScore: 50,
          observationScore: 40,
          observationCount: 2,
          confirmedObservationCount: 1,
        ),
      );

      expect(
        connected.factorWeights['observations'],
        0.20,
      );
    },
  );

  test(
    'an unavailable hazard factor leaves only the exposure factors',
    () {
      final assessment = calculator.calculate(
        HazardRiskInput(
          hazard: HazardType.storm,
          primaryFactorLabel: 'Wind gusts',
          variables: <HazardVariable>[
            _variable(
              name: 'gust',
              weight: 1.0,
              value: 30,
            ),
          ],
          vulnerabilityScore: 60,
        ),
      );

      expect(assessment.hazardAvailable, isFalse);
      expect(assessment.hazardScore, 0);
      expect(
        assessment.factorWeights,
        <String, double>{'vulnerability': 0.25},
      );
      expect(
        assessment.overallScore,
        closeTo(60, 0.001),
      );
    },
  );

  test(
    'an inverted variable scores from its low outer reference',
    () {
      final inverted = calculator.calculate(
        HazardRiskInput(
          hazard: HazardType.wildfire,
          primaryFactorLabel: 'Fire weather',
          variables: <HazardVariable>[
            _variable(
              name: 'soil',
              weight: 1.0,
              value: 5,
              referenceValue: 10,
              statisticalCriticalValue: 4,
              inverted: true,
            ),
          ],
        ),
      );

      expect(
        inverted.hazardScore,
        greaterThan(50),
      );
      expect(inverted.hazardScore, lessThan(100));
    },
  );

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
    expect(assessment.factorWeights, isEmpty);
  });
}