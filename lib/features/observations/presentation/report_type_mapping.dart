import '../domain/observation.dart';
import '../../risk/domain/hazard_type.dart';

/// Maps wizard catastrophe ids to [ObservationType] + hazard label (EN).
class ReportTypeMapping {
  const ReportTypeMapping._();

  static ObservationType observationType(String? typeId) {
    switch (typeId) {
      case 'flood':
      case 'flooding':
      case 'tsunami':
      case 'marine':
        return ObservationType.flooding;
      case 'landslide':
        return ObservationType.landslide;
      default:
        return ObservationType.other;
    }
  }

  /// Hazard label stored in Firestore (same convention as ObservationsScreen).
  static String hazardLabel(String? typeId, {String? preferred}) {
    if (preferred != null && preferred.trim().isNotEmpty) {
      final fromId = HazardType.fromId(preferred);
      if (fromId != null) {
        return fromId.label;
      }
      final fromLabel = HazardType.fromLabel(preferred);
      if (fromLabel != null) {
        return fromLabel.label;
      }
      return preferred.trim();
    }

    switch (typeId) {
      case 'flood':
      case 'flooding':
      case 'tsunami':
      case 'marine':
        return HazardType.flooding.label;
      case 'landslide':
        return HazardType.landslide.label;
      case 'heatwave':
      case 'drought':
        return HazardType.heat.label;
      default:
        return HazardType.flooding.label;
    }
  }
}
