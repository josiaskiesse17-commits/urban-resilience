import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/hazard_variable.dart';
import 'package:urban_resilience/features/risk/domain/risk_evidence.dart';
import 'package:urban_resilience/features/risk/domain/risk_factors.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement_label.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_simulation.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';



HazardVariable _heatVariable({
  required String name,
  required String label,
  required double weight,
  required double value,
  required double reference,
  required double critical,
}) {
  return HazardVariable(
    name: name,
    label: label,
    value: value,
    unit: '°C',
    measurementPeriod: '24h',
    weight: weight,
    referenceValue: reference,
    statisticalCriticalValue: critical,
    referenceLabel: 'Median of the month of January',
    referenceType: RiskReferenceType.historicalMedian,
    source: 'Open-Meteo Weather API',
    observedAt: DateTime.utc(2026, 1, 15, 12),
  );
}



RiskResult _storedHeatResult() {
  return const RiskIntelligenceService().calculateHazardRisk(
    id: 'zone-test--heat',
    locationName: 'Test Zone',
    latitude: -4.3,
    longitude: 15.32,
    input: HazardRiskInput(
      hazard: HazardType.heat,
      primaryFactorLabel: 'Heat',
      variables: <HazardVariable>[
        _heatVariable(
          name: 'temperature2mMax24h',
          label: 'Maximum air temperature (24 h)',
          weight: 0.45,
          value: 36,
          reference: 32,
          critical: 40,
        ),
        _heatVariable(
          name: 'apparentTemperatureMax24h',
          label: 'Maximum apparent temperature (24 h)',
          weight: 0.40,
          value: 44,
          reference: 34,
          critical: 42,
        ),
        _heatVariable(
          name: 'temperature2mMin24h',
          label: 'Night-time minimum temperature (24 h)',
          weight: 0.15,
          value: 26,
          reference: 24,
          critical: 28,
        ),
      ],
      vulnerabilityScore: 49.5,
    ),
  );
}



RiskResult _heatResultWithoutReference() {
  final timestamp = DateTime.utc(2026, 1, 15, 12);

  return RiskResult(
    id: 'zone-test--heat',
    locationName: 'Test Zone',
    latitude: -4.3,
    longitude: 15.32,
    hazardType: 'Heat',
    riskScore: 64,
    riskLevel: RiskLevel.high,
    factors: const RiskFactors(
      rainfall: 74,
      geographicVulnerability: 40,
      historicalExposure: 0,
      currentObservations: 0,
      primaryFactorLabel: 'Heat',
    ),
    evidence: RiskEvidence(
      measurements: const <RiskMeasurement>[
        RiskMeasurement(
          name: 'temperature2mMin24h',
          value: 26,
          unit: '°C',
          measurementPeriod: '24h',
          source: 'Open-Meteo Weather API',
        ),
      ],
      qualitativeIndicators: const <String>[],
      observationCount: 0,
      confirmedObservationCount: 0,
      collectedAt: timestamp,
    ),
    updatedAt: timestamp,
  );
}

void main() {
  const service = RiskSimulationService();

  test(
    'the simulation starts from the stored assessment with the same engine',
    () {
      final result = _storedHeatResult();
      final model = service.modelFrom(result)!;

      expect(model.currentScore, result.riskScore);
      expect(model.currentLevel, result.riskLevel);

      
      
      final outcome = service.simulate(model: model)!;

      expect(outcome.score, closeTo(result.riskScore, 0.0001));
      expect(outcome.level, result.riskLevel);
      expect(outcome.difference.abs(), lessThan(0.05));
      expect(outcome.levelChanged, isFalse);
    },
  );

  test(
    'the controls are the hazard-specific variables of this assessment',
    () {
      final model = service.modelFrom(_storedHeatResult())!;

      expect(
        model.variables.map((variable) => variable.name),
        <String>[
          'temperature2mMax24h',
          'apparentTemperatureMax24h',
          'temperature2mMin24h',
        ],
      );

      
      expect(
        model.variables.map((variable) => variable.name),
        isNot(contains('riverDischarge')),
      );
      expect(
        model.variables.map((variable) => variable.name),
        isNot(contains('soilMoisture0to7cm')),
      );
      expect(
        model.variables.map((variable) => variable.name),
        isNot(contains('rainfallAccumulation6h')),
      );

      
      expect(
        model.variables.first.label,
        'Température maximale de l’air — dernières 24 heures',
      );
      expect(
        model.variables.first.label,
        RiskMeasurementLabel.of(
          name: 'temperature2mMax24h',
          measurementPeriod: '24h',
          unit: '°C',
        ),
      );

      expect(model.adjustable, hasLength(3));
    },
  );

  test(
    'changing a major input changes only the simulated outcome',
    () {
      final result = _storedHeatResult();
      final storedJson = result.toJson().toString();
      final model = service.modelFrom(result)!;

      final outcome = service.simulate(
        model: model,
        values: const <String, double>{
          'temperature2mMax24h': 44,
        },
      )!;

      expect(outcome.values['temperature2mMax24h'], 44);
      expect(outcome.score, greaterThan(result.riskScore));
      expect(outcome.riskIncreased, isTrue);

      
      expect(result.toJson().toString(), storedJson);
      expect(model.currentScore, result.riskScore);

      
      final again = service.simulate(
        model: model,
        values: const <String, double>{
          'temperature2mMax24h': 44,
        },
      )!;

      expect(again.score, outcome.score);
      expect(again.level, outcome.level);
    },
  );

  test(
    'a measurement without a statistical reference is not adjustable',
    () {
      final model = service.modelFrom(_heatResultWithoutReference())!;

      expect(
        model.variables.map((variable) => variable.name),
        contains('temperature2mMin24h'),
      );
      expect(model.adjustable, isEmpty);
      expect(
        model.fixed.map((variable) => variable.name),
        contains('temperature2mMin24h'),
      );
      expect(model.isSimulatable, isFalse);
      expect(model.unavailableReason, isNotNull);
      expect(service.simulate(model: model), isNull);
    },
  );
}
