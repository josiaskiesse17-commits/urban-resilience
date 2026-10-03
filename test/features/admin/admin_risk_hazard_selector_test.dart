import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/admin/presentation/screens/admin_risk_screen.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_ai_providers.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';

import '../risk/risk_result_test_support.dart';
import '../risk/risk_test_fakes.dart';


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

RiskResult _resultFor(
  String zoneName,
  String zoneId,
  HazardType hazard,
) {
  final isFlooding = hazard == HazardType.flooding;

  return buildRiskResult(
    id: isFlooding ? zoneId : '$zoneId--${hazard.id}',
    locationName: zoneName,
    hazardType: isFlooding ? 'Flood' : hazard.label,
    primaryFactorLabel: isFlooding ? 'Rainfall' : 'Heat',
    riskScore: isFlooding ? 64 : 38,
    riskLevel:
        isFlooding ? RiskLevel.high : RiskLevel.medium,
  );
}

Widget buildHost({
  required MapRiskResultRepository repository,
  required List<String> generated,
}) {
  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider
          .overrideWith((ref) => repository),
      riskExposureRepositoryProvider.overrideWith(
        (ref) => FakeRiskExposureRepository(),
      ),
      riskAnalystProvider.overrideWith(
        (ref) => FakeRiskAnalyst(),
      ),
      zoneHazardRiskGeneratorProvider.overrideWith(
        (ref) => (zone, hazard) async {
          generated.add(hazard.id);

          final result = _resultFor(
            zone.name,
            zone.id,
            hazard,
          );

          repository.stored[result.id] = result;

          return result;
        },
      ),
    ],
    child: const MaterialApp(
      home: AdminRiskScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'the hazard selector generates the document of the selected hazard',
    (tester) async {
      final repository = MapRiskResultRepository();
      final generated = <String>[];

      await tester.pumpWidget(
        buildHost(
          repository: repository,
          generated: generated,
        ),
      );
      await tester.pumpAndSettle();

      
      
      expect(generated, <String>[HazardType.flooding.id]);
      expect(
        repository.stored.keys,
        <String>['zone-masina'],
      );
      expect(
        repository.stored['zone-masina']!.hazardType,
        'Flood',
      );

      
      expect(find.text('Scénario hypothétique'), findsOneWidget);

      await tester.tap(
        find.text(HazardType.heat.labelFr),
      );
      await tester.pumpAndSettle();

      expect(
        generated,
        <String>[
          HazardType.flooding.id,
          HazardType.heat.id,
        ],
      );

      
      expect(
        repository.stored.keys,
        containsAll(<String>[
          'zone-masina',
          'zone-masina--heat',
        ]),
      );
      expect(
        repository.stored['zone-masina']!.riskScore,
        64,
      );
      expect(
        repository.stored['zone-masina--heat']!.hazardType,
        HazardType.heat.label,
      );
      expect(
        repository.stored['zone-masina--heat']!.riskScore,
        38,
      );

      
      expect(find.text('Scénario hypothétique'), findsNothing);
    },
  );
}