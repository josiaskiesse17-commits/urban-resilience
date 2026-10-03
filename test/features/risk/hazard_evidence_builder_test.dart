import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_evidence_builder.dart';
import 'package:urban_resilience/features/risk/domain/hazard_variable.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';

void main() {
  final variable = HazardVariable(
    name: 'windGusts10mMax6h',
    label: 'Maximum wind gust (6 h)',
    value: 72,
    unit: 'km/h',
    measurementPeriod: '6h',
    weight: 0.45,
    referenceValue: 40,
    statisticalCriticalValue: 65,
    referenceLabel: 'Median of the month of January',
    referenceType: RiskReferenceType.historicalMedian,
    historicalPercentile: 92.5,
    source: 'Open-Meteo Weather API',
    observedAt: DateTime.utc(2026, 9, 29, 6),
    isDerived: true,
    derivationNote: 'strongest 10 m wind gust of the last 6 hours',
  );

  test('maps every field of a hazard variable', () {
    final measurement = HazardEvidenceBuilder.measurementFrom(
      variable,
    );

    expect(measurement.name, 'windGusts10mMax6h');
    expect(measurement.value, 72);
    expect(measurement.unit, 'km/h');
    expect(measurement.measurementPeriod, '6h');
    expect(measurement.referenceValue, 40);
    expect(measurement.referenceUnit, 'km/h');
    expect(
      measurement.referenceLabel,
      'Median of the month of January',
    );
    expect(
      measurement.referenceType,
      RiskReferenceType.historicalMedian,
    );
    expect(measurement.ratioToReference, closeTo(1.8, 0.0001));
    expect(measurement.differenceFromReference, closeTo(32, 0.0001));
    expect(measurement.historicalPercentile, 92.5);
    expect(measurement.statisticalCriticalValue, 65);
    expect(
      measurement.statisticalCriticalLabel,
      contains('95e centile'),
    );
    expect(
      measurement.statisticalCriticalLabel,
      contains('non un seuil de sécurité officiel'),
    );
    expect(measurement.isDerived, isTrue);
    expect(
      measurement.derivationNote,
      contains('last 6 hours'),
    );
    expect(
      measurement.source,
      'Open-Meteo Weather API',
    );
    expect(
      measurement.observedAt,
      DateTime.utc(2026, 9, 29, 6),
    );
  });

  test(
    'an inverted variable is labelled with its 5th percentile',
    () {
      final measurement =
          HazardEvidenceBuilder.measurementFrom(
        HazardVariable(
          name: 'soilMoisture',
          label: 'Topsoil water content',
          value: 0.08,
          unit: 'm³/m³',
          measurementPeriod: 'instant',
          weight: 0.35,
          referenceValue: 0.22,
          statisticalCriticalValue: 0.06,
          inverted: true,
        ),
      );

      expect(
        measurement.statisticalCriticalLabel,
        contains('5e centile'),
      );
      expect(
        measurement.ratioToReference,
        closeTo(0.08 / 0.22, 0.0001),
      );
    },
  );

  test('maps a list of variables in order', () {
    final measurements = HazardEvidenceBuilder.measurementsFrom([
      variable,
      HazardVariable(
        name: 'cape',
        label: 'CAPE',
        value: 500,
        unit: 'J/kg',
        measurementPeriod: 'instant',
        weight: 0,
        informational: true,
      ),
    ]);

    expect(measurements, hasLength(2));
    expect(measurements.first.name, 'windGusts10mMax6h');
    expect(measurements.last.name, 'cape');
    expect(measurements.last.referenceValue, isNull);
    expect(measurements.last.statisticalCriticalLabel, isNull);
  });
}