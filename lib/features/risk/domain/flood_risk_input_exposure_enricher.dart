import 'flood_risk_input.dart';
import 'flood_risk_input_exposure_extension.dart';
import 'risk_exposure_repository.dart';

class FloodRiskInputExposureEnricher {
  const FloodRiskInputExposureEnricher({
    required this._repository,
  });

  final RiskExposureRepository _repository;

  Future<FloodRiskInput> enrich({
    required String zoneId,
    required FloodRiskInput input,
  }) async {
    final profile = await _repository.getProfile(zoneId);

    if (profile == null) {
      return input;
    }

    return input.withExposureProfile(profile);
  }
}