import 'flood_risk_exposure_profile.dart';

abstract class RiskExposureRepository {
  Future<FloodRiskExposureProfile?> getProfile(String zoneId);

  Future<void> saveProfile(FloodRiskExposureProfile profile);
}
