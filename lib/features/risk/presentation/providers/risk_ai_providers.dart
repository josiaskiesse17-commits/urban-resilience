import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firebase_ai_risk_analyst.dart';
import '../../domain/risk_analysis.dart';
import '../../domain/risk_analyst.dart';
import '../../domain/risk_result.dart';

final riskAnalystProvider = Provider<RiskAnalyst>((ref) {
  return FirebaseAiRiskAnalyst();
});

final riskAnalysisProvider =
    FutureProvider.family<RiskAnalysis, RiskResult>(
  (ref, riskResult) {
    return ref.read(riskAnalystProvider).analyze(riskResult);
  },
);