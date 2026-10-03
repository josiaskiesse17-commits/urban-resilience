import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/risk_analysis.dart';
import 'package:urban_resilience/features/risk/domain/risk_analyst.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';

class FakeRiskResultRepository implements RiskResultRepository {
  RiskResult? stored;
  int getCalls = 0;

  @override
  Future<void> save(RiskResult result) async {
    stored = result;
  }

  @override
  Future<RiskResult?> get(String riskId) async {
    getCalls++;

    return stored?.id == riskId ? stored : null;
  }

  @override
  Future<RiskResult?> getLatestForZone(String zoneId) async {
    return stored?.id == zoneId ? stored : null;
  }
}

class StoredByHazardRepository implements RiskResultRepository {
  StoredByHazardRepository([Map<String, RiskResult>? initial])
    : stored = <String, RiskResult>{...?initial};

  final Map<String, RiskResult> stored;

  Object? failure;

  int getCalls = 0;

  @override
  Future<RiskResult?> get(String riskId) async {
    getCalls++;

    final error = failure;

    if (error != null) {
      throw error;
    }

    return stored[riskId];
  }

  @override
  Future<RiskResult?> getLatestForZone(String zoneId) async {
    return stored[zoneId];
  }

  @override
  Future<void> save(RiskResult result) async {
    stored[result.id] = result;
  }
}

class FakeRiskExposureRepository implements RiskExposureRepository {
  FloodRiskExposureProfile? profile;

  @override
  Future<FloodRiskExposureProfile?> getProfile(String zoneId) async {
    return profile;
  }

  @override
  Future<void> saveProfile(FloodRiskExposureProfile newProfile) async {
    profile = newProfile;
  }
}

class FakeRiskAnalyst implements RiskAnalyst {
  int calls = 0;
  Object? failure;

  @override
  Future<RiskAnalysis> analyze(RiskResult riskResult) async {
    calls++;

    final currentFailure = failure;

    if (currentFailure != null) {
      throw currentFailure;
    }

    return RiskAnalysis(
      riskId: riskResult.id,
      summary: 'AI summary for ${riskResult.locationName}.',
      explanation: 'AI explanation for the stored assessment.',
      mainFactors: const <String>['Heavy rainfall'],
      recommendations: const <String>['Avoid flooded roads'],
      generatedAt: DateTime.now(),
    );
  }
}
