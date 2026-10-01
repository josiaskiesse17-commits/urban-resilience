import 'hazard_type.dart';

/// Builds and parses the risk id of a hazard assessment.
///
/// The id is both the `risk_results/{riskId}` document id and the `/risk/:id`
/// route parameter, so it has to be stable and URL safe.
///
/// * flooding keeps the historic id (the bare zone id, for example
///   `zone-masina`) so the documents and routes that already exist keep
///   resolving without a migration;
/// * every other hazard is stored under `<zoneId>--<hazardId>`, for example
///   `zone-masina--heat`.
class HazardRiskId {
  const HazardRiskId._();

  static const String separator = '--';

  static String forZone({
    required String zoneId,
    required HazardType hazard,
  }) {
    if (hazard == HazardType.legacyDefault) {
      return zoneId;
    }

    return '$zoneId$separator${hazard.id}';
  }

  /// Hazard of a risk id. Ids without a known hazard suffix are flooding.
  static HazardType hazardOf(String riskId) {
    final index = riskId.lastIndexOf(separator);

    if (index < 0) {
      return HazardType.legacyDefault;
    }

    final suffix = riskId.substring(index + separator.length);

    return HazardType.fromId(suffix) ??
        HazardType.legacyDefault;
  }

  /// Zone a risk id belongs to, without its hazard suffix.
  static String zoneIdOf(String riskId) {
    final index = riskId.lastIndexOf(separator);

    if (index < 0) {
      return riskId;
    }

    final suffix = riskId.substring(index + separator.length);

    if (HazardType.fromId(suffix) == null) {
      return riskId;
    }

    return riskId.substring(0, index);
  }
}
