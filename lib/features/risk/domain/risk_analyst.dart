import 'risk_analysis.dart';
import 'risk_result.dart';

abstract class RiskAnalyst {
  Future<RiskAnalysis> analyze(RiskResult riskResult);
}