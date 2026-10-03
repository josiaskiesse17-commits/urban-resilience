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
        note: 'Aucun profil d’exposition enregistré n’a été trouvé pour cette '
            'zone (document `risk_zones` absent). La vulnérabilité et '
            'l’exposition historique sont inconnues, et non nulles : elles '
            'sont exclues de ce score et leurs poids sont portés par les '
            'facteurs disponibles.',
      );
    }

    if (hazard == HazardType.flooding) {
      return (
        vulnerabilityScore: profile.vulnerabilityScore,
        historicalExposureScore: profile.historicalFloodExposureScore,
        note: 'La vulnérabilité combine l’exposition de la population, des '
            'infrastructures, du drainage et des équipements critiques du '
            'profil de zone enregistré ; l’exposition historique est '
            'l’exposition historique aux inondations du même document.',
      );
    }

    final vulnerability =
        (profile.populationExposureScore * 0.35) +
            (profile.infrastructureExposureScore * 0.35) +
            (profile.criticalFacilityExposureScore * 0.30);

    return (
      vulnerabilityScore: vulnerability.clamp(0.0, 100.0),
      historicalExposureScore: null,
      note: 'La vulnérabilité combine l’exposition de la population, des '
          'infrastructures et des équipements critiques du profil de zone '
          'enregistré. La vulnérabilité au drainage et l’exposition '
          'historique aux inondations du même document ne décrivent que les '
          'inondations : elles ne sont donc pas réutilisées pour '
          '${hazard.labelFr.toLowerCase()}, et aucune exposition '
          'historique propre à ce risque n’est disponible. Ce facteur est '
          'exclu au lieu d’être compté comme un zéro.',
    );
  }
}
