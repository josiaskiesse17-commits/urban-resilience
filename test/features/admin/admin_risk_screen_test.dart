import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/admin/presentation/screens/admin_risk_screen.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import '../risk/risk_result_test_support.dart';
import '../risk/risk_test_fakes.dart';

Widget buildAdminHost({
  required FakeRiskResultRepository repository,
  required FakeRiskExposureRepository exposureRepository,
  required FakeRiskAnalyst analyst,
  required ZoneRiskGenerator generator,
}) {
  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider.overrideWith((ref) => repository),
      riskExposureRepositoryProvider.overrideWith((ref) => exposureRepository),
      riskAnalystProvider.overrideWith((ref) => analyst),
      zoneRiskGeneratorProvider.overrideWith((ref) => generator),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) =>
            (zone, hazard) => generator(zone),
      ),
    ],
    child: const MaterialApp(home: AdminRiskScreen()),
  );
}

Widget buildCitizenHost({
  required FakeRiskResultRepository repository,
  required FakeRiskExposureRepository exposureRepository,
  required FakeRiskAnalyst analyst,
  required ZoneRiskGenerator generator,
}) {
  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider.overrideWith((ref) => repository),
      riskExposureRepositoryProvider.overrideWith((ref) => exposureRepository),
      riskAnalystProvider.overrideWith((ref) => analyst),
      zoneRiskGeneratorProvider.overrideWith((ref) => generator),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) =>
            (zone, hazard) => generator(zone),
      ),
    ],
    child: const MaterialApp(home: RiskDetailsScreen(riskId: 'zone-masina')),
  );
}

void main() {
  testWidgets(
    'Admin Risk loads the same stored RiskResult source as the citizen flow',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(
          riskScore: 64,
          riskLevel: RiskLevel.critical,
        );
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      await tester.pumpWidget(
        buildAdminHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async {
            generatorCalls++;
            return repository.stored!;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CRITIQUE'), findsWidgets);
      expect(find.text('64'), findsWidgets);
      expect(find.textContaining('Mis à jour'), findsWidgets);

      expect(find.text('Éléments de preuve'), findsOneWidget);
      expect(find.textContaining('observations reçues'), findsOneWidget);
      expect(find.text('Mesures clés'), findsOneWidget);
      expect(find.textContaining('Source : Open-Meteo'), findsWidgets);

      expect(generatorCalls, 0);
    },
  );

  testWidgets(
    'Admin recalculate persists a new result the citizen screen then reads',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(
          riskScore: 64,
          riskLevel: RiskLevel.critical,
        );
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      await tester.pumpWidget(
        buildAdminHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async {
            generatorCalls++;

            final updated = buildRiskResult(
              id: zone.id,
              locationName: zone.name,
              riskScore: 81,
              riskLevel: RiskLevel.critical,
            );

            await repository.save(updated);

            return updated;
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(generatorCalls, 0);

      final recalculate = find.text('Recalculer le risque actuel');
      await tester.ensureVisible(recalculate);
      await tester.tap(recalculate);
      await tester.pumpAndSettle();

      expect(generatorCalls, 1);
      expect(repository.stored, isNotNull);
      expect(repository.stored!.riskScore, 81);

      expect(find.text('81'), findsWidgets);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        buildCitizenHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async {
            generatorCalls++;
            return repository.stored!;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('81/100'), findsOneWidget);
      expect(find.text('CRITIQUE'), findsOneWidget);

      expect(generatorCalls, 1);
      expect(analyst.calls, 1);
    },
  );
}
