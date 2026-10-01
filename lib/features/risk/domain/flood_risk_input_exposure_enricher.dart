import 'flood_risk_exposure_profile.dart';
import 'flood_risk_input.dart';
import 'flood_risk_input_exposure_extension.dart';
import 'risk_exposure_repository.dart';

/// Result of looking up the stored exposure profile of a zone.
///
/// [profile] is null when no `risk_zones/{zoneId}` document exists. Callers
/// can therefore report missing exposure data explicitly instead of letting
/// the missing values be read as "no vulnerability".
typedef FloodRiskInputExposureEnrichment = ({
  FloodRiskInput input,
  FloodRiskExposureProfile? profile,
});

class FloodRiskInputExposureEnricher {
  const FloodRiskInputExposureEnricher({
    required this._repository,
  });

  final RiskExposureRepository _repository;

  /// Reads the stored exposure profile once and reports whether it exists.
  Future<FloodRiskInputExposureEnrichment> enrichWithProfile({
    required String zoneId,
    required FloodRiskInput input,
  }) async {
    final profile = await _repository.getProfile(zoneId);

    if (profile == null) {
      return (
        input: input,
        profile: null,
      );
    }

    return (
      input: input.withExposureProfile(profile),
      profile: profile,
    );
  }

  Future<FloodRiskInput> enrich({
    required String zoneId,
    required FloodRiskInput input,
  }) async {
    final enrichment = await enrichWithProfile(
      zoneId: zoneId,
      input: input,
    );

    return enrichment.input;
  }
}