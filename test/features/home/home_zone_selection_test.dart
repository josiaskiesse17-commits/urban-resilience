import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:urban_resilience/features/home/presentation/home_screen.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import '../risk/risk_result_test_support.dart';
import '../risk/risk_test_fakes.dart';

void main() {
  testWidgets(
    'selecting a zone opens its real risk information directly',
    (tester) async {
      final repository = FakeRiskResultRepository()
        ..stored = buildRiskResult(
          riskScore: 62,
          riskLevel: RiskLevel.high,
        );
      final exposureRepository = FakeRiskExposureRepository();
      final analyst = FakeRiskAnalyst();
      var generatorCalls = 0;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/risk/:id',
            builder: (context, state) => RiskDetailsScreen(
              riskId: state.pathParameters['id']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riskResultRepositoryProvider
                .overrideWith((ref) => repository),
            riskExposureRepositoryProvider
                .overrideWith((ref) => exposureRepository),
            riskAnalystProvider.overrideWith((ref) => analyst),
            zoneRiskGeneratorProvider.overrideWith((ref) => (zone) async {
              generatorCalls++;
              return repository.stored!;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Masina'), findsWidgets);

      await tester.tap(find.text('Masina'));
      await tester.pumpAndSettle();

      // The zone's stored assessment is on screen without pressing
      // anything else: no hidden generation/setup step exists.
      expect(find.text('Risk Analysis'), findsOneWidget);
      expect(find.text('62/100'), findsOneWidget);
      expect(generatorCalls, 0);

      // The AI interpreted the loaded result exactly once.
      expect(analyst.calls, 1);

      router.dispose();
    },
  );
}
