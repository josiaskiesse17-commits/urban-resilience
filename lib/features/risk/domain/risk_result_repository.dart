import 'risk_result.dart';

abstract class RiskResultRepository {
  Future<void> save(RiskResult result);

  Future<RiskResult?> get(String riskId);

  Future<RiskResult?> getLatestForZone(String zoneId);
}
