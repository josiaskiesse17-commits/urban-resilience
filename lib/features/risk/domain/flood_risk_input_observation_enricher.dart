import '../../observations/domain/observation.dart';
import '../../observations/domain/observation_risk_calculator.dart';
import 'flood_risk_input.dart';

class FloodRiskInputObservationEnricher {
  const FloodRiskInputObservationEnricher({
    ObservationRiskCalculator? observationRiskCalculator,
  }) : _observationRiskCalculator =
           observationRiskCalculator ?? const ObservationRiskCalculator();

  final ObservationRiskCalculator _observationRiskCalculator;

  FloodRiskInput enrich({
    required double latitude,
    required double longitude,
    required FloodRiskInput input,
    required List<Observation> observations,
    Duration lookback = const Duration(hours: 24),
    double radiusKm = 5,
  }) {
    final calculation = _observationRiskCalculator.calculate(
      latitude: latitude,
      longitude: longitude,
      observations: observations,
      lookback: lookback,
      radiusKm: radiusKm,
    );

    return input.copyWith(
      observationScore: calculation.score,
      observationCount: calculation.observationCount,
      confirmedObservationCount: calculation.confirmedObservationCount,
    );
  }
}
