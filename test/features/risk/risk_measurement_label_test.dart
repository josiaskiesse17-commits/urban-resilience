import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/risk_measurement_label.dart';

void main() {
  group('RiskMeasurementLabel', () {
    test('spells out the window carried by the identifier', () {
      expect(
        RiskMeasurementLabel.of(name: 'rainfallAccumulation30d'),
        'Cumul de pluie — derniers 30 jours',
      );
      expect(
        RiskMeasurementLabel.of(name: 'rainfallAccumulation24h'),
        'Cumul de pluie — dernières 24 heures',
      );
      expect(
        RiskMeasurementLabel.of(name: 'rainfallAccumulation6h'),
        'Cumul de pluie — dernières 6 heures',
      );
      expect(
        RiskMeasurementLabel.of(name: 'rainfallAccumulation14d'),
        'Cumul de pluie — derniers 14 jours',
      );
    });

    test('spells out a unit embedded in the identifier', () {
      expect(
        RiskMeasurementLabel.of(name: 'rainfallIntensityMmPerHour'),
        'Intensité de la pluie — mm/h',
      );
      expect(
        RiskMeasurementLabel.of(name: 'riverDischargeM3s'),
        'Débit fluvial — m³/s',
      );
    });

    test('uses the measurement period when the identifier carries none', () {
      expect(
        RiskMeasurementLabel.of(
          name: 'riverDischarge',
          measurementPeriod: 'daily',
        ),
        'Débit fluvial — moyenne journalière',
      );
      expect(
        RiskMeasurementLabel.of(
          name: 'rainfallIntensity',
          measurementPeriod: '1h',
        ),
        'Intensité de la pluie — dernière heure',
      );
      expect(
        RiskMeasurementLabel.of(
          name: 'soilMoisture0to7cm',
          measurementPeriod: 'instant',
        ),
        'Contenu en eau de la couche 0-7 cm',
      );
    });

    test('keeps a window and a unit together', () {
      expect(
        RiskMeasurementLabel.of(name: 'rainfallAccumulation6hMm'),
        'Cumul de pluie — dernières 6 heures (mm)',
      );
    });

    test('labels the exposure factors with their plain name', () {
      expect(
        RiskMeasurementLabel.of(name: 'geographicVulnerability'),
        'Vulnérabilité géographique',
      );
      expect(
        RiskMeasurementLabel.of(name: 'citizenObservationRisk'),
        'Risque lié aux observations citoyennes',
      );
    });

    test('falls back to a readable split of an unknown identifier', () {
      expect(
        RiskMeasurementLabel.of(name: 'customSensorAlpha'),
        'Custom sensor alpha',
      );
    });

    test('never returns an empty label', () {
      expect(RiskMeasurementLabel.of(name: ''), '');
    });
  });
}
