import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/risk_analysis.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import 'risk_result_test_support.dart';
import 'risk_test_fakes.dart';

Widget buildHost({
  required FakeRiskResultRepository repository,
  required FakeRiskExposureRepository exposureRepository,
  required FakeRiskAnalyst analyst,
  required ZoneRiskGenerator generator,
  String riskId = 'zone-masina',
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
    child: MaterialApp(home: RiskDetailsScreen(riskId: riskId)),
  );
}

void main() {
  testWidgets(
    'loads the stored RiskResult and runs the AI analyst exactly once',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(riskScore: 62, riskLevel: RiskLevel.high);
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      await tester.pumpWidget(
        buildHost(
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

      // The real stored result is displayed.
      expect(find.text('Masina'), findsWidgets);
      expect(find.text('62/100'), findsOneWidget);
      expect(find.text('ÉLEVÉ'), findsOneWidget);
      // A fresh stored result is reused: no regeneration happened.
      expect(generatorCalls, 0);

      // The AI interpreted exactly this stored result, once.
      expect(analyst.calls, 1);
      expect(find.text('AI summary for Masina.'), findsOneWidget);

      // The interpretation was persisted with the evaluation so a later visit
      // reuses it instead of asking the AI again.
      expect(repository.stored!.analysis, isNotNull);
      expect(
        repository.stored!.analysis!.summary,
        'AI summary for Masina.',
      );

      // Rebuilding never starts another AI request.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(analyst.calls, 1);
      expect(generatorCalls, 0);
    },
  );

  testWidgets(
    'generates and persists a missing result without any user action',
    (tester) async {
      final repository = FakeRiskResultRepository();
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async {
            generatorCalls++;

            final generated = buildRiskResult(
              id: zone.id,
              locationName: zone.name,
              riskScore: 71,
              riskLevel: RiskLevel.high,
            );

            // The shared pipeline persists its result before returning it.
            await repository.save(generated);

            return generated;
          },
        ),
      );

      await tester.pumpAndSettle();

      // The zone had no result, so exactly one run happened automatically:
      // no "Generate live risk" button was pressed anywhere.
      expect(generatorCalls, 1);
      expect(repository.stored, isNotNull);
      expect(repository.stored!.id, 'zone-masina');

      // The generated result is now on screen.
      expect(find.text('71/100'), findsOneWidget);
      expect(find.text('ÉLEVÉ'), findsOneWidget);

      // The AI ran once for the generated result.
      expect(analyst.calls, 1);

      // Rebuilds never trigger another generation.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(generatorCalls, 1);
      expect(analyst.calls, 1);
    },
  );

  testWidgets(
    'AI failure is shown once, never loops, and Retry works explicitly',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(riskScore: 62, riskLevel: RiskLevel.high);
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst()
        ..failure = Exception('proxy unavailable');

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async => repository.stored!,
        ),
      );

      await tester.pumpAndSettle();

      // The request ran once and failed once.
      expect(analyst.calls, 1);
      expect(
        find.text('L’analyse IA n’a pas pu être générée.'),
        findsOneWidget,
      );
      expect(find.textContaining('proxy unavailable'), findsWidgets);
      expect(find.text('Réessayer l’analyse IA'), findsOneWidget);

      // No automatic retry, however long we wait.
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 30));
      expect(analyst.calls, 1);

      // The explicit Retry button runs the request again and succeeds.
      analyst.failure = null;

      final retry = find.text('Réessayer l’analyse IA');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(analyst.calls, 2);
      expect(find.text('AI summary for Masina.'), findsOneWidget);
      expect(find.text('Retry AI analysis'), findsNothing);
    },
  );

  testWidgets('reports missing exposure data explicitly instead of "safe"', (
    tester,
  ) async {
    final repository = FakeRiskResultRepository()
      ..stored = buildRiskResult(riskScore: 62, riskLevel: RiskLevel.high);
    final exposureRepository = FakeRiskExposureRepository();
    final analyst = FakeRiskAnalyst();

    await tester.pumpWidget(
      buildHost(
        repository: repository,
        exposureRepository: exposureRepository,
        analyst: analyst,
        generator: (zone) async => repository.stored!,
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Aucun profil d’exposition n’est enregistré pour cette zone.'),
      findsOneWidget,
    );
    expect(find.textContaining('inconnues, et non nulles'), findsWidgets);
  });

  testWidgets(
    'recalculating stores a new result and reinterprets only that result',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(riskScore: 62, riskLevel: RiskLevel.high);
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async {
            generatorCalls++;

            final updated = buildRiskResult(
              id: zone.id,
              locationName: zone.name,
              riskScore: 79,
              riskLevel: RiskLevel.critical,
            );

            await repository.save(updated);

            return updated;
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(analyst.calls, 1);

      final refresh = find.text('Recalculer le risque');
      await tester.ensureVisible(refresh);
      await tester.tap(refresh);
      await tester.pumpAndSettle();

      // Exactly one recalculation ran and its result was persisted.
      expect(generatorCalls, 1);
      expect(repository.stored, isNotNull);
      expect(repository.stored!.riskScore, 79);

      // The refreshed result replaced the old one on screen.
      expect(find.text('79/100'), findsOneWidget);
      expect(find.text('CRITIQUE'), findsOneWidget);

      // The new result version was interpreted once more, then stayed stable.
      expect(analyst.calls, 2);
      await tester.pump();
      expect(analyst.calls, 2);

      // Flush the confirmation SnackBar timer before the test ends.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'a stored AI interpretation is reused without another AI request',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(riskScore: 62, riskLevel: RiskLevel.high)
            .withAnalysis(
          RiskAnalysis(
            riskId: 'zone-masina',
            summary: 'Interprétation enregistrée pour Masina.',
            explanation: 'Elle est réutilisée telle quelle.',
            mainFactors: const <String>['Températures élevées'],
            recommendations: const <String>['Boire de l’eau'],
            generatedAt: DateTime.utc(2026, 1, 5, 6),
          ),
        );
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          exposureRepository: exposureRepository,
          analyst: analyst,
          generator: (zone) async => repository.stored!,
        ),
      );

      await tester.pumpAndSettle();

      // The interpretation stored with the evaluation is displayed and the AI
      // was never asked again for it.
      expect(analyst.calls, 0);
      expect(
        find.text('Interprétation enregistrée pour Masina.'),
        findsOneWidget,
      );

      // Rebuilding the screen does not start an AI request either.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(analyst.calls, 0);
    },
  );
}
