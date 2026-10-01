import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/risk_measurement_label.dart';

void main() {
  group('RiskMeasurementLabel', () {
    test(
      'spells out the window carried by the identifier',
      () {
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallAccumulation30d',
          ),
          'Rainfall accumulation — 30 days',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallAccumulation24h',
          ),
          'Rainfall accumulation — 24 hours',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallAccumulation6h',
          ),
          'Rainfall accumulation — 6 hours',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallAccumulation14d',
          ),
          'Rainfall accumulation — 14 days',
        );
      },
    );

    test(
      'spells out a unit embedded in the identifier',
      () {
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallIntensityMmPerHour',
          ),
          'Rainfall intensity — mm/hour',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'riverDischargeM3s',
          ),
          'River discharge — m³/s',
        );
      },
    );

    test(
      'uses the measurement period when the identifier carries none',
      () {
        expect(
          RiskMeasurementLabel.of(
            name: 'riverDischarge',
            measurementPeriod: 'daily',
          ),
          'River discharge — daily mean',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallIntensity',
            measurementPeriod: '1h',
          ),
          'Rainfall intensity — last hour',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'soilMoisture0to7cm',
            measurementPeriod: 'instant',
          ),
          'Topsoil water content (0-7 cm)',
        );
      },
    );

    test(
      'keeps a window and a unit together',
      () {
        expect(
          RiskMeasurementLabel.of(
            name: 'rainfallAccumulation6hMm',
          ),
          'Rainfall accumulation — 6 hours (mm)',
        );
      },
    );

    test(
      'labels the exposure factors with their plain name',
      () {
        expect(
          RiskMeasurementLabel.of(
            name: 'geographicVulnerability',
          ),
          'Geographic vulnerability',
        );
        expect(
          RiskMeasurementLabel.of(
            name: 'citizenObservationRisk',
          ),
          'Citizen observation risk',
        );
      },
    );

    test(
      'falls back to a readable split of an unknown identifier',
      () {
        expect(
          RiskMeasurementLabel.of(name: 'customSensorAlpha'),
          'Custom sensor alpha',
        );
      },
    );

    test('never returns an empty label', () {
      expect(RiskMeasurementLabel.of(name: ''), '');
    });
  });
}
