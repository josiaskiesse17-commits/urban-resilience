import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/observations/domain/observation.dart';
import 'package:urban_resilience/features/observations/domain/observation_risk_calculator.dart';

void main() {
  const calculator = ObservationRiskCalculator();

  group('ObservationRiskCalculator', () {
    test('recent confirmed flooding observation contributes to risk', () {
      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-1',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.confirmed,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final result = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: observations,
      );

      expect(result.observationCount, 1);
      expect(result.confirmedObservationCount, 1);
      expect(result.score, greaterThan(0));
    });

    test('pending observation is counted but does not contribute to risk', () {
      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-2',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.pending,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final result = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: observations,
      );

      expect(result.observationCount, 1);
      expect(result.confirmedObservationCount, 0);
      expect(result.score, 0);
    });

    test('rejected observation is counted but does not contribute to risk', () {
      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-3',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.rejected,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final result = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: observations,
      );

      expect(result.observationCount, 1);
      expect(result.confirmedObservationCount, 0);
      expect(result.score, 0);
    });

    test('observation outside the radius is ignored', () {
      final now = DateTime.now().toUtc();

      final observations = [
        Observation(
          id: 'obs-4',
          userId: 'user-1',
          latitude: 10,
          longitude: 10,
          type: ObservationType.flooding,
          status: ObservationStatus.confirmed,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final result = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: observations,
      );

      expect(result.observationCount, 0);
      expect(result.confirmedObservationCount, 0);
      expect(result.score, 0);
    });

    test('old observation is ignored', () {
      final observations = [
        Observation(
          id: 'obs-5',
          userId: 'user-1',
          latitude: 0,
          longitude: 0,
          type: ObservationType.flooding,
          status: ObservationStatus.confirmed,
          createdAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        ),
      ];

      final result = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: observations,
        lookback: const Duration(hours: 24),
      );

      expect(result.observationCount, 0);
      expect(result.confirmedObservationCount, 0);
      expect(result.score, 0);
    });

    test('blocked road contributes less than flooding', () {
      final now = DateTime.now().toUtc();

      final flooding = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: [
          Observation(
            id: 'flood',
            userId: 'user-1',
            latitude: 0,
            longitude: 0,
            type: ObservationType.flooding,
            status: ObservationStatus.confirmed,
            createdAt: now,
          ),
        ],
      );

      final blockedRoad = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: [
          Observation(
            id: 'road',
            userId: 'user-1',
            latitude: 0,
            longitude: 0,
            type: ObservationType.blockedRoad,
            status: ObservationStatus.confirmed,
            createdAt: now,
          ),
        ],
      );

      expect(flooding.score, greaterThan(blockedRoad.score));
    });

    test('multiple confirmed observations increase the score', () {
      final now = DateTime.now().toUtc();

      final oneObservation = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: [
          Observation(
            id: 'obs-1',
            userId: 'user-1',
            latitude: 0,
            longitude: 0,
            type: ObservationType.flooding,
            status: ObservationStatus.confirmed,
            createdAt: now,
          ),
        ],
      );

      final multipleObservations = calculator.calculate(
        latitude: 0,
        longitude: 0,
        observations: [
          Observation(
            id: 'obs-1',
            userId: 'user-1',
            latitude: 0,
            longitude: 0,
            type: ObservationType.flooding,
            status: ObservationStatus.confirmed,
            createdAt: now,
          ),
          Observation(
            id: 'obs-2',
            userId: 'user-2',
            latitude: 0,
            longitude: 0,
            type: ObservationType.flooding,
            status: ObservationStatus.confirmed,
            createdAt: now,
          ),
        ],
      );

      expect(multipleObservations.score, greaterThan(oneObservation.score));

      expect(multipleObservations.confirmedObservationCount, 2);
    });
  });
}
