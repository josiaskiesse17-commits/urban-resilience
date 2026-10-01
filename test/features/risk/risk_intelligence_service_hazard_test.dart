import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/hazard_variable.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';

HazardVariable _scorable({
  double weight = 0.7,
  double value = 120,
}) {
  return HazardVariable(
    name: 'temperature2mMax24h',
    label: 'Maximum air temperature (24 h)',
    value: value,
    unit: '°C',
    measurementPeriod: '24h',
    weight: weight,
    referenceValue: 32,
    statisticalCriticalValue: 40,
    referenceLabel: 'Median of the month of January',
    referenceType: RiskReferenceType.historicalMedian,
    historicalPercentile: 88,
    source: 'Open-Meteo Weather API',
    observedAt: DateTime.utc(2026, 1, 15, 12),
  );
}

HazardVariable _informational() {
  return const HazardVariable(
    name: 'convectiveAvailablePotentialEnergy',
    label: 'Convective available potential energy',
    value: 900,
    unit: 'J/kg',
    measurementPeriod: 'instant',
    weight: 0,
    informational: true,
  );
}

void main() {
  const service = RiskIntelligenceService();

  test(
    'builds a complete evidence for a generic hazard',
    () {
      final result = service.calculateHazardRisk(
        id: 'zone-test--heat',
        locationName: 'Test Zone',
        latitude: -4.3,
        longitude: 15.32,
        input: HazardRiskInput(
          hazard: HazardType.heat,
          primaryFactorLabel: 'Heat',
          variables: <HazardVariable>[
            _scorable(),
            _informational(),
          ],
          gaps: const <HazardVariableGap>[
            HazardVariableGap(
              name: 'apparentTemperatureMax24h',
              label: 'Maximum apparent temperature (24 h)',
              reason: 'the live provider returned no value',
            ),
          ],
          vulnerabilityScore: 55,
          limitations: const <String>[
            'No official heat-health warning threshold is used.',
          ],
          notes: const <String>['provider note'],
          referencePeriodStart: DateTime.utc(2018, 1, 1),
          referencePeriodEnd: DateTime.utc(2022, 7, 31),
          referenceSource: 'ERA5',
          partialReference: true,
        ),
      );

      expect(result.id, 'zone-test--heat');
      expect(result.hazardType, 'Heat');
      expect(result.riskScore, greaterThan(0));

      final evidence = result.evidence;

      // Both hazard variables reach the evidence with their own
      // unit, source and statistical reference.
      expect(
        evidence.measurements.map((item) => item.name),
        containsAll(<String>[
          'temperature2mMax24h',
          'convectiveAvailablePotentialEnergy',
        ]),
      );

      final indicators = evidence.qualitativeIndicators.join('\n');

      expect(indicators, contains('Statistical reference:'));
      expect(indicators, contains('2018-01-01 – 2022-07-31'));
      expect(indicators, contains('(ERA5)'));
      expect(
        indicators,
        contains('not official safety thresholds'),
      );
      expect(
        indicators,
        contains('same calendar month'),
      );
      expect(
        indicators,
        contains('Not measured: Maximum apparent temperature'),
      );
      expect(
        indicators,
        contains('not as zero'),
      );
      expect(indicators, contains('provider note'));
      expect(
        indicators,
        contains('Model limitation: No official heat-health'),
      );
      expect(
        indicators,
        contains('Overall score weights applied'),
      );
      expect(
        indicators,
        contains('not connected in this release'),
      );

      // The evidence timestamp is the observation time of the live value.
      expect(
        evidence.collectedAt,
        DateTime.utc(2026, 1, 15, 12),
      );
      expect(evidence.observationCount, 0);
    },
  );

  test(
    'reports an unavailable hazard factor instead of a silent zero',
    () {
      final result = service.calculateHazardRisk(
        id: 'zone-test--storm',
        locationName: 'Test Zone',
        latitude: -4.3,
        longitude: 15.32,
        input: const HazardRiskInput(
          hazard: HazardType.storm,
          primaryFactorLabel: 'Wind gusts',
          variables: <HazardVariable>[],
        ),
      );

      final indicators =
          result.evidence.qualitativeIndicators.join('\n');

      expect(
        indicators,
        contains(
          'No environmental variable of this hazard could be scored',
        ),
      );
      expect(result.riskScore, 0);
    },
  );

  test(
    'an exposure note and a missing profile reach the evidence',
    () {
      final result = service.calculateHazardRisk(
        id: 'zone-test--drought',
        locationName: 'Test Zone',
        latitude: -4.3,
        longitude: 15.32,
        input: HazardRiskInput(
          hazard: HazardType.drought,
          primaryFactorLabel: 'Rainfall deficit (30 d)',
          variables: <HazardVariable>[_scorable()],
          exposureProfileMissing: true,
          exposureNote:
              'No stored exposure profile was found for this zone.',
        ),
      );

      final indicators =
          result.evidence.qualitativeIndicators.join('\n');

      expect(
        indicators,
        contains('No stored exposure profile'),
      );
      expect(result.hazardType, 'Drought');
    },
  );
}