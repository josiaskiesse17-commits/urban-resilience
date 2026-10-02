import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:urban_resilience/features/map/presentation/widgets/zone_active_risks_sheet.dart';
import 'package:urban_resilience/features/risk/data/risk_repository.dart';
import 'package:urban_resilience/features/risk/domain/hazard_risk_id.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

import '../risk/risk_result_test_support.dart';
import '../risk/risk_test_fakes.dart';

final RiskZoneTarget _masina = RiskZoneCatalog.byId('zone-masina')!;

RiskResult _identified({
  required String id,
  required String hazardType,
  required double riskScore,
  required RiskLevel riskLevel,
}) {
  return buildRiskResult(
    id: id,
    hazardType: hazardType,
    riskScore: riskScore,
    riskLevel: riskLevel,
  );
}

/// Hosts the Zone Active Risks sheet behind a button, with the risk details
/// route available so a row can open it exactly like the map does.
Widget buildSheetHost({
  required StoredByHazardRepository repository,
  required List<String> generated,
}) {
  final router = GoRouter(
    initialLocation: '/host',
    routes: [
      GoRoute(
        path: '/host',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showZoneActiveRisksSheet(context, _masina),
                child: const Text('open zone'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/risk/:id',
        builder: (context, state) => RiskDetailsScreen(
          riskId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider.overrideWith((ref) => repository),
      riskExposureRepositoryProvider.overrideWith(
        (ref) => FakeRiskExposureRepository(),
      ),
      riskAnalystProvider.overrideWith((ref) => FakeRiskAnalyst()),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) => (zone, hazard) async {
          generated.add(hazard.id);

          final result = _identified(
            id: HazardRiskId.forZone(
              zoneId: zone.id,
              hazard: hazard,
            ),
            hazardType: hazard.label,
            riskScore: 71,
            riskLevel: RiskLevel.critical,
          );

          await repository.save(result);

          return result;
        },
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required StoredByHazardRepository repository,
  required List<String> generated,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    buildSheetHost(
      repository: repository,
      generated: generated,
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('open zone'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'lists the identified risks of the zone, most severe first',
    (tester) async {
      final repository = StoredByHazardRepository()
        ..stored['zone-masina'] = _identified(
          id: 'zone-masina',
          hazardType: 'Flood',
          riskScore: 62,
          riskLevel: RiskLevel.high,
        )
        ..stored['zone-masina--heat'] = _identified(
          id: 'zone-masina--heat',
          hazardType: 'Heat',
          riskScore: 71,
          riskLevel: RiskLevel.critical,
        );

      await _openSheet(
        tester,
        repository: repository,
        generated: <String>[],
      );

      expect(find.text('Masina'), findsOneWidget);
      expect(
        find.text('2 active risks identified in this zone.'),
        findsOneWidget,
      );
      expect(find.text('Active risks'), findsOneWidget);
      expect(find.text('Other hazards'), findsOneWidget);

      // The most severe identified risk is listed first.
      expect(
        tester.getTopLeft(find.text(HazardType.heat.label)).dy,
        lessThan(
          tester.getTopLeft(find.text(HazardType.flooding.label)).dy,
        ),
      );
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);

      // The hazards that carry no current risk stay reachable.
      expect(find.text(HazardType.landslide.label), findsOneWidget);
      expect(find.text('Not assessed'), findsOneWidget);
    },
  );

  testWidgets(
    'a zone without identified risk says so instead of showing zeroes',
    (tester) async {
      final repository = StoredByHazardRepository()
        ..stored['zone-masina--landslide'] = _identified(
          id: 'zone-masina--landslide',
          hazardType: 'Landslide',
          riskScore: 0,
          riskLevel: RiskLevel.low,
        );

      await _openSheet(
        tester,
        repository: repository,
        generated: <String>[],
      );

      expect(
        find.text('No active risk identified in this zone right now.'),
        findsOneWidget,
      );
      expect(find.text('Active risks'), findsNothing);
      expect(
        find.textContaining('nothing is shown as a zero'),
        findsOneWidget,
      );

      // The stored zero is not an active risk.
      expect(find.text('No risk'), findsOneWidget);
      expect(find.text('Other hazards'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed read is reported with an explicit Retry',
    (tester) async {
      final repository = StoredByHazardRepository()
        ..failure = Exception('offline');

      await _openSheet(
        tester,
        repository: repository,
        generated: <String>[],
      );

      expect(
        find.text('Could not load the stored risks of Masina.'),
        findsOneWidget,
      );
      expect(find.textContaining('offline'), findsOneWidget);

      repository.failure = null;

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Other hazards'), findsOneWidget);
      expect(find.text(HazardType.landslide.label), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a hazard opens the risk details of that hazard document',
    (tester) async {
      final repository = StoredByHazardRepository()
        ..stored['zone-masina'] = _identified(
          id: 'zone-masina',
          hazardType: 'Flood',
          riskScore: 62,
          riskLevel: RiskLevel.high,
        );
      final generated = <String>[];

      await _openSheet(
        tester,
        repository: repository,
        generated: generated,
      );

      await tester.tap(find.text(HazardType.heat.label));
      await tester.pumpAndSettle();

      // The details screen of the heat hazard generated exactly that document.
      expect(generated, <String>[HazardType.heat.id]);
      expect(
        repository.stored.keys,
        containsAll(<String>['zone-masina', 'zone-masina--heat']),
      );
      expect(repository.stored['zone-masina']!.riskScore, 62);
      expect(repository.stored['zone-masina--heat']!.riskScore, 71);
      expect(find.text('71/100'), findsOneWidget);
    },
  );
}
