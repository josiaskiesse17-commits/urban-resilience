import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import 'risk_result_test_support.dart';
import 'risk_test_fakes.dart';

/// One document per risk id, like the `risk_results` collection: it proves a
/// hazard never overwrites the assessment of another hazard of the same zone.
class MapRiskResultRepository implements RiskResultRepository {
  final Map<String, RiskResult> stored = <String, RiskResult>{};

  @override
  Future<RiskResult?> get(String riskId) async => stored[riskId];

  @override
  Future<RiskResult?> getLatestForZone(String zoneId) async =>
      stored[zoneId];

  @override
  Future<void> save(RiskResult result) async {
    stored[result.id] = result;
  }
}

Widget buildHazardHost({
  required MapRiskResultRepository repository,
  required FakeRiskExposureRepository exposureRepository,
  required FakeRiskAnalyst analyst,
  required List<String> generatedHazards,
  String riskId = 'zone-masina',
}) {
  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider
          .overrideWith((ref) => repository),
      riskExposureRepositoryProvider
          .overrideWith((ref) => exposureRepository),
      riskAnalystProvider.overrideWith((ref) => analyst),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) => (zone, hazard) async {
          generatedHazards.add(hazard.id);

          final isHeat = hazard == HazardType.heat;
          final result = buildRiskResult(
            id: isHeat ? '${zone.id}--heat' : zone.id,
            locationName: zone.name,
            hazardType: isHeat ? 'Heat' : 'Flood',
            riskScore: isHeat ? 71 : 62,
            riskLevel: isHeat
                ? RiskLevel.critical
                : RiskLevel.high,
            primaryFactorLabel: isHeat ? 'Heat' : 'Rainfall',
          );

          repository.stored[result.id] = result;

          return result;
        },
      ),
    ],
    child: MaterialApp(
      home: RiskDetailsScreen(riskId: riskId),
    ),
  );
}

void main() {
  testWidgets(
    'switching the hazard loads and generates its own document',
    (tester) async {
      final repository = MapRiskResultRepository()
        ..stored['zone-masina'] = buildRiskResult();
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      final generated = <String>[];

      await tester.pumpWidget(
        buildHazardHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generatedHazards: generated,
        ),
      );
      await tester.pumpAndSettle();

      // The flooding assessment of the zone, untouched by the switch.
      expect(find.text('62/100'), findsOneWidget);
      expect(generated, isEmpty);
      expect(
        find.text(HazardType.heat.label),
        findsOneWidget,
      );

      await tester.tap(
        find.text(HazardType.heat.label),
      );
      await tester.pumpAndSettle();

      expect(generated, <String>[HazardType.heat.id]);
      expect(find.text('71/100'), findsOneWidget);

      // Both documents now exist: the heat one was added, not substituted
      // for the flooding one.
      expect(
        repository.stored.keys,
        containsAll(<String>[
          'zone-masina',
          'zone-masina--heat',
        ]),
      );
      expect(repository.stored['zone-masina']!.riskScore, 62);
      expect(
        repository.stored['zone-masina--heat']!.riskScore,
        71,
      );
      expect(
        repository.stored['zone-masina--heat']!.hazardType,
        'Heat',
      );
    },
  );

  testWidgets(
    'a hazard document is labelled with its own primary factor',
    (tester) async {
      final repository = MapRiskResultRepository()
        ..stored['zone-masina--wildfire'] = buildRiskResult(
          id: 'zone-masina--wildfire',
          hazardType: 'Wildfire',
          primaryFactorLabel: 'Fire weather',
          riskScore: 44,
          riskLevel: RiskLevel.medium,
        );
      final generated = <String>[];

      await tester.pumpWidget(
        buildHazardHost(
          repository: repository,
          exposureRepository: FakeRiskExposureRepository(),
          analyst: FakeRiskAnalyst(),
          generatedHazards: generated,
          riskId: 'zone-masina--wildfire',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('44/100'), findsOneWidget);
      expect(find.text('Fire weather'), findsOneWidget);
      expect(find.text('Rainfall'), findsNothing);

      // The document was already fresh: nothing had to be generated.
      expect(generated, isEmpty);
    },
  );
}