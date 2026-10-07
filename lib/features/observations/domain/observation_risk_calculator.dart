import 'dart:math' as math;

import 'observation.dart';

class ObservationRiskCalculation {
  const ObservationRiskCalculation({
    required this.score,
    required this.observationCount,
    required this.confirmedObservationCount,
  });

  final double score;
  final int observationCount;
  final int confirmedObservationCount;
}

class ObservationRiskCalculator {
  const ObservationRiskCalculator();

  ObservationRiskCalculation calculate({
    required double latitude,
    required double longitude,
    required List<Observation> observations,
    Duration lookback = const Duration(hours: 24),
    double radiusKm = 5,
  }) {
    final now = DateTime.now().toUtc();

    var score = 0.0;
    var observationCount = 0;
    var confirmedObservationCount = 0;

    for (final observation in observations) {
      final createdAt = observation.createdAt.toUtc();
      final age = now.difference(createdAt);

      if (age.isNegative || age > lookback) {
        continue;
      }

      final distanceKm = _distanceKm(
        latitude1: latitude,
        longitude1: longitude,
        latitude2: observation.latitude,
        longitude2: observation.longitude,
      );

      if (distanceKm > radiusKm) {
        continue;
      }

      observationCount++;

      if (observation.status != ObservationStatus.confirmed) {
        continue;
      }

      confirmedObservationCount++;

      final typeWeight = _typeWeight(observation.type);

      final distanceWeight = (1 - (distanceKm / radiusKm)).clamp(0.0, 1.0);

      final ageRatio = age.inMinutes / math.max(lookback.inMinutes, 1);

      final recencyWeight = (1 - ageRatio).clamp(0.0, 1.0);

      score += typeWeight * distanceWeight * recencyWeight;
    }

    return ObservationRiskCalculation(
      score: score.clamp(0.0, 100.0),
      observationCount: observationCount,
      confirmedObservationCount: confirmedObservationCount,
    );
  }

  double _typeWeight(ObservationType type) {
    switch (type) {
      case ObservationType.flooding:
        return 35;

      case ObservationType.blockedRoad:
        return 20;

      case ObservationType.landslide:
        return 10;

      case ObservationType.heat:
        return 15;

      case ObservationType.other:
        return 5;
    }
  }

  double _distanceKm({
    required double latitude1,
    required double longitude1,
    required double latitude2,
    required double longitude2,
  }) {
    const earthRadiusKm = 6371.0;

    final lat1 = _toRadians(latitude1);
    final lat2 = _toRadians(latitude2);

    final deltaLat = _toRadians(latitude2 - latitude1);

    final deltaLon = _toRadians(longitude2 - longitude1);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
