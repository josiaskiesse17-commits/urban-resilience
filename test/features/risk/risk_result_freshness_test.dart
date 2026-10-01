import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/risk_result_freshness.dart';

import 'risk_result_test_support.dart';

void main() {
  test(
    'a missing result always needs an update',
    () {
      expect(
        RiskResultFreshness.needsUpdate(null),
        isTrue,
      );
    },
  );

  test(
    'a stored result inside the freshness window is reused',
    () {
      final result = buildRiskResult(
        updatedAt: DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 1)),
      );

      expect(
        RiskResultFreshness.needsUpdate(result),
        isFalse,
      );
    },
  );

  test(
    'a stored result older than the window is regenerated',
    () {
      final result = buildRiskResult(
        updatedAt: DateTime.now()
            .toUtc()
            .subtract(
              RiskResultFreshness.maxAge + const Duration(minutes: 1),
            ),
      );

      expect(
        RiskResultFreshness.needsUpdate(result),
        isTrue,
      );
    },
  );

  test(
    'clock skew does not force a regeneration',
    () {
      final result = buildRiskResult(
        updatedAt: DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 5)),
      );

      expect(
        RiskResultFreshness.needsUpdate(result),
        isFalse,
      );
    },
  );
}
