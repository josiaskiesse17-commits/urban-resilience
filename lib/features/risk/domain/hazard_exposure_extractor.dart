import 'flood_risk_exposure_profile.dart';
import 'hazard_type.dart';

typedef HazardExposure = ({
  double? vulnerabilityScore,
  double? historicalExposureScore,
  String note,
});

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
        note:
            'Aucun profil d’exposition enregistré n’a été trouvé pour cette '
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
        note:
            'La vulnérabilité combine l’exposition de la population, des '
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
      note:
          'La vulnérabilité combine l’exposition de la population, des '
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
