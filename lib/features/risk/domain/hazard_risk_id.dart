import 'hazard_type.dart';

class HazardRiskId {
  const HazardRiskId._();

  static const String separator = '--';

  static String forZone({required String zoneId, required HazardType hazard}) {
    if (hazard == HazardType.legacyDefault) {
      return zoneId;
    }

    return '$zoneId$separator${hazard.id}';
  }

  static HazardType hazardOf(String riskId) {
    final index = riskId.lastIndexOf(separator);

    if (index < 0) {
      return HazardType.legacyDefault;
    }

    final suffix = riskId.substring(index + separator.length);

    return HazardType.fromId(suffix) ?? HazardType.legacyDefault;
  }

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
