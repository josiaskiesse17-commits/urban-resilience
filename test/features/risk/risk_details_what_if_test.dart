import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/data/risk_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_evidence.dart';
import 'package:urban_resilience/features/risk/domain/risk_factor_score.dart';
import 'package:urban_resilience/features/risk/domain/risk_factors.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import 'risk_test_fakes.dart';

/// A fresh, stored heat assessment with its factor breakdown and evidence,
/// as the Risk Details screen receives it from `risk_results`.
RiskResult _storedHeatResult() {
  final timestamp = DateTime.now().toUtc();

  return RiskResult(
    id: 'zone-masina--heat',
    locationName: 'Masina',
    latitude: -4.30,
    longitude: 15.35,
    hazardType: 'Heat',
    riskScore: 62,
    riskLevel: RiskLevel.high,
    factors: RiskFactors(
      rainfall: 74,
      geographicVulnerability: 40,
      historicalExposure: 0,
      currentObservations: 0,
      primaryFactorLabel: 'Heat',
      entries: const <RiskFactorScore>[
        RiskFactorScore(
          name: 'hazard',
          label: 'Heat',
          score: 74,
          weight: 0.40,
          usedInScore: true,
          componentNames: <String>[
            'temperature2mMax24h',
            'apparentTemperatureMax24h',
            'temperature2mMin24h',
          ],
        ),
        RiskFactorScore(
          name: 'temperature2mMax24h',
          label: 'Maximum air temperature — 24 hours',
          score: 60,
          weight: 0.45,
          usedInScore: true,
        ),
        RiskFactorScore(
          name: 'apparentTemperatureMax24h',
          label: 'Maximum apparent temperature — 24 hours',
          score: 85,
          weight: 0.40,
          usedInScore: true,
        ),
        RiskFactorScore(
          name: 'temperature2mMin24h',
          label: 'Night-time minimum temperature — 24 hours',
          score: 40,
          weight: 0.15,
          usedInScore: true,
        ),
        RiskFactorScore(
          name: 'geographicVulnerability',
          label: 'Geographic vulnerability',
          score: 40,
          weight: 0.25,
          usedInScore: true,
        ),
        RiskFactorScore(
          name: 'historicalExposure',
          label: 'Historical exposure',
          weight: 0,
          usedInScore: false,
          unavailableReason:
              'no historical exposure of this zone is stored for heat',
        ),
        RiskFactorScore(
          name: 'citizenObservationRisk',
          label: 'Citizen observations',
          weight: 0,
          usedInScore: false,
          unavailableReason:
              'citizen observations are not connected in this release',
        ),
      ],
    ),
    evidence: RiskEvidence(
      measurements: <RiskMeasurement>[
        RiskMeasurement(
          name: 'temperature2mMax24h',
          value: 36,
          unit: '°C',
          measurementPeriod: '24h',
          referenceValue: 32,
          referenceUnit: '°C',
          referenceLabel: 'Median of the month of January',
          statisticalCriticalValue: 40,
          source: 'Open-Meteo Weather API',
          observedAt: DateTime(2026, 1, 15, 12),
        ),
        RiskMeasurement(
          name: 'apparentTemperatureMax24h',
          value: 44,
          unit: '°C',
          measurementPeriod: '24h',
          referenceValue: 34,
          referenceUnit: '°C',
          statisticalCriticalValue: 42,
          source: 'Open-Meteo Weather API',
          observedAt: DateTime(2026, 1, 15, 12),
        ),
        RiskMeasurement(
          name: 'temperature2mMin24h',
          value: 26,
          unit: '°C',
          measurementPeriod: '24h',
          referenceValue: 24,
          referenceUnit: '°C',
          statisticalCriticalValue: 28,
          source: 'Open-Meteo Weather API',
          observedAt: DateTime(2026, 1, 15, 12),
        ),
      ],
      qualitativeIndicators: const <String>[
        'Statistical reference: 2021-01-01 – 2021-02-14 (ERA5).',
      ],
      observationCount: 0,
      confirmedObservationCount: 0,
      collectedAt: timestamp,
    ),
    updatedAt: timestamp,
  );
}

Widget buildHost({
  required FakeRiskResultRepository repository,
  required FakeRiskExposureRepository exposureRepository,
  required FakeRiskAnalyst analyst,
}) {
  // The stored result is fresh, so no generation may ever run during these
  // tests: a call is a failure.
  Future<RiskResult> unexpectedGeneration(RiskZoneTarget zone) async {
    throw StateError(
      'the stored assessment must not be regenerated: ${zone.id}',
    );
  }

  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider
          .overrideWith((ref) => repository),
      riskExposureRepositoryProvider
          .overrideWith((ref) => exposureRepository),
      riskAnalystProvider.overrideWith((ref) => analyst),
      zoneRiskGeneratorProvider
          .overrideWith((ref) => unexpectedGeneration),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) => (zone, hazard) => unexpectedGeneration(zone),
      ),
    ],
    child: MaterialApp(
      home: RiskDetailsScreen(riskId: 'zone-masina--heat'),
    ),
  );
}


void main() {
  testWidgets(
    'the What-If simulator sits below the AI explanation and is no forecast',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = _storedHeatResult();
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
        ),
      );

      await tester.pumpAndSettle();

      // The AI explained the real stored assessment, exactly once.
      expect(analyst.calls, 1);
      expect(find.text('AI summary for Masina.'), findsOneWidget);

      double topOf(Finder finder) => tester.getTopLeft(finder).dy;

      // Section order: Risk Factors -> Evidence -> AI -> What-If.
      expect(
        topOf(find.text('Risk Factors')),
        lessThan(topOf(find.text('Evidence'))),
      );
      expect(
        topOf(find.text('Evidence')),
        lessThan(topOf(find.text('AI Risk Analyst'))),
      );
      expect(
        topOf(find.text('AI Risk Analyst')),
        lessThan(topOf(find.text('What-If Scenario'))),
      );

      // The simulator declares itself a hypothetical scenario, never a
      // forecast of what will happen.
      expect(find.textContaining('not a forecast'), findsWidgets);
      expect(find.text('Simulated result'), findsNothing);
    },
  );

  testWidgets(
    'running a scenario changes only the What-If section',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = _storedHeatResult();
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
        ),
      );

      await tester.pumpAndSettle();
      expect(analyst.calls, 1);

      final slider = find.byType(Slider).first;
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();

      await tester.drag(slider, const Offset(300, 0));
      await tester.pumpAndSettle();

      // The hypothetical outcome is rendered inside the What-If section.
      expect(find.text('Simulated result'), findsOneWidget);
      expect(find.textContaining('not a forecast'), findsWidgets);
      expect(
        find.textContaining(
          'does not change the assessment, the factors, the evidence '
          'or the AI explanation above',
        ),
        findsOneWidget,
      );

      // The real assessment above is untouched by the scenario.
      expect(find.text('62/100'), findsWidgets);
      expect(find.text('AI summary for Masina.'), findsOneWidget);

      // A scenario never invokes the AI analyst.
      expect(analyst.calls, 1);
    },
  );
}
