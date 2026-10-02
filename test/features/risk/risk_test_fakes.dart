import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/risk_analysis.dart';
import 'package:urban_resilience/features/risk/domain/risk_analyst.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';

/// In-memory [RiskResultRepository] shared by the citizen, home and admin
/// widget tests. One instance represents the single `risk_results` source of
/// truth all screens read and write.
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

/// In-memory `risk_results` collection with one document per risk id, used by
/// the map / Zone Active Risks flow tests. It can also fail explicit reads so
/// the error states of those surfaces are covered.
class StoredByHazardRepository implements RiskResultRepository {
  StoredByHazardRepository([Map<String, RiskResult>? initial])
      : stored = <String, RiskResult>{...?initial};

  final Map<String, RiskResult> stored;

  /// When set, every read throws it instead of returning a document.
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

/// In-memory exposure repository. A null [profile] represents a zone whose
/// `risk_zones/{zoneId}` document does not exist yet.
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

/// Counting [RiskAnalyst] whose success/failure can be flipped mid-test to
/// verify the run-once lifecycle and the explicit Retry button.
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
