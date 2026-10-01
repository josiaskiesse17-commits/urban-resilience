import 'hazard_environmental_data.dart';
import 'hazard_type.dart';

/// Historical series of a hazard over a reference period.
class HazardHistoricalData {
  const HazardHistoricalData({
    required this.hazard,
    required this.series,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    required this.source,
  });

  final HazardType hazard;

  /// Series keyed by provider field.
  final Map<String, HazardSeries> series;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;
  final String source;

  HazardSeries? seriesFor(String field) => series[field];
}
