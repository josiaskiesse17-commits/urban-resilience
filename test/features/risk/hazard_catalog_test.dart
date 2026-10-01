import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_catalog.dart';
import 'package:urban_resilience/features/risk/domain/hazard_definition.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';

void main() {
  test(
    'every hazard has a definition and only flooding is legacy',
    () {
      for (final hazard in HazardType.values) {
        final definition = HazardCatalog.of(hazard);

        expect(definition.hazard, hazard);
        expect(definition.primaryFactorLabel, isNotEmpty);
        expect(definition.description, isNotEmpty);
        expect(
          definition.legacyPipeline,
          hazard == HazardType.flooding,
        );
      }
    },
  );

  test('labels and ids are unique', () {
    final labels = HazardType.values
        .map((hazard) => hazard.label)
        .toSet();
    final ids = HazardType.values
        .map((hazard) => hazard.id)
        .toSet();

    expect(labels.length, HazardType.values.length);
    expect(ids.length, HazardType.values.length);
  });

  test(
    'generic hazards declare scored weights that add up to one',
    () {
      for (final hazard in HazardCatalog.genericHazards) {
        final definition = HazardCatalog.of(hazard);

        expect(definition.legacyPipeline, isFalse);
        expect(definition.scoredVariables, isNotEmpty);
        expect(
          definition.totalScoredWeight,
          closeTo(1.0, 0.0001),
          reason: hazard.label,
        );

        for (final spec in definition.variables) {
          expect(spec.label, isNotEmpty);
          expect(spec.unit, isNotEmpty);

          if (spec.informational) {
            continue;
          }

          expect(spec.weight, greaterThan(0));
          expect(spec.hasHistoricalReference, isTrue);
        }
      }
    },
  );

  test(
    'the flooding inventory is informational for the generic engine',
    () {
      final flooding = HazardCatalog.flooding;

      expect(flooding.seasonalReference, isFalse);
      expect(flooding.primaryFactorLabel, 'Rainfall');
      expect(
        flooding.variables.every(
          (spec) => spec.informational,
        ),
        isTrue,
      );
    },
  );

  test(
    'historical requests skip live-only and flood-sourced fields',
    () {
      for (final hazard in HazardType.values) {
        final definition = HazardCatalog.of(hazard);

        for (final spec in definition.variables) {
          if (spec.source ==
              HazardVariableSource.openMeteoFlood) {
            expect(
              definition.liveApiFields,
              isNot(contains(spec.apiField)),
            );
            expect(
              definition.historicalApiFields,
              isNot(contains(spec.apiField)),
            );

            continue;
          }

          expect(
            definition.liveApiFields,
            contains(spec.apiField),
          );

          if (!spec.hasHistoricalReference) {
            expect(
              definition.historicalApiFields,
              isNot(contains(spec.apiField)),
            );
          }
        }
      }
    },
  );

  test('usesLegacyPipeline matches the legacy flag', () {
    expect(
      HazardCatalog.usesLegacyPipeline(HazardType.flooding),
      isTrue,
    );

    for (final hazard in HazardCatalog.genericHazards) {
      expect(
        HazardCatalog.usesLegacyPipeline(hazard),
        isFalse,
      );
    }

    expect(
      HazardCatalog.genericHazards,
      isNot(contains(HazardType.flooding)),
    );
    expect(
      HazardCatalog.allHazards,
      HazardType.values,
    );
  });
}