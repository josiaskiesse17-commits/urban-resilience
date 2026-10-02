import 'flood_risk_exposure_profile.dart';
import 'hazard_type.dart';

/// Exposure / vulnerability of a zone for one hazard.
typedef HazardExposure = ({
  double? vulnerabilityScore,
  double? historicalExposureScore,
  String note,
});

/// Derives the hazard-appropriate vulnerability from the exposure profile
/// that is already stored in `risk_zones/{zoneId}`.
///
/// The stored document is shared by every hazard, but two of its sub-scores
/// only describe flooding (drainage vulnerability and historical flood
/// exposure). Reusing them for heat or landslide would score one hazard with
/// measurements of another, so they are reported as not available for those
/// hazards instead of being silently counted.
class HazardExposureExtractor {
  const HazardExposureExtractor();

  HazardExposure extract({
    required HazardType hazard,
    required FloodRiskExposureProfile? profile,
  }) {
    if (profile == null) {
      return (
        vulnerabilityScore: null,
        historicalExposureScore: null,
        note: 'No stored exposure profile was found for this zone '
            '(`risk_zones` document missing). Vulnerability and historical '
            'exposure are unknown, not zero: they are excluded from this '
            'score and its weights are carried by the available factors.',
      );
    }

    if (hazard == HazardType.flooding) {
      return (
        vulnerabilityScore: profile.vulnerabilityScore,
        historicalExposureScore: profile.historicalFloodExposureScore,
        note: 'Vulnerability combines population, infrastructure, drainage '
            'and critical-facility exposure from the stored zone profile; '
            'historical exposure is the stored historical flood exposure of '
            'the same document.',
      );
    }

    final vulnerability =
        (profile.populationExposureScore * 0.35) +
            (profile.infrastructureExposureScore * 0.35) +
            (profile.criticalFacilityExposureScore * 0.30);

    return (
      vulnerabilityScore: vulnerability.clamp(0.0, 100.0),
      historicalExposureScore: null,
      note: 'Vulnerability combines population, infrastructure and '
          'critical-facility exposure of the stored zone profile. Drainage '
          'vulnerability and historical flood exposure of the same document '
          'describe flooding only, so they are not reused for '
          '${hazard.label.toLowerCase()} and no hazard-specific historical '
          'exposure is available: that factor is excluded instead of being '
          'counted as zero.',
    );
  }
}
