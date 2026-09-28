import 'flood_risk_exposure_profile.dart';
import 'flood_risk_input.dart';

extension FloodRiskInputExposureExtension on FloodRiskInput {
  FloodRiskInput withExposureProfile(
    FloodRiskExposureProfile profile,
  ) {
    return copyWith(
      vulnerabilityScore: profile.vulnerabilityScore,
      historicalExposureScore:
          profile.historicalFloodExposureScore,
    );
  }
}