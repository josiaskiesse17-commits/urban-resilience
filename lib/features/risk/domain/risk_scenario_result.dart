import 'risk_result.dart';

class RiskScenarioResult {
  final RiskResult baseline;
  final RiskResult scenario;

  final double scoreDifference;
  final bool riskLevelChanged;

  const RiskScenarioResult({
    required this.baseline,
    required this.scenario,
    required this.scoreDifference,
    required this.riskLevelChanged,
  });

  bool get riskIncreased => scoreDifference > 0;

  bool get riskDecreased => scoreDifference < 0;
}
