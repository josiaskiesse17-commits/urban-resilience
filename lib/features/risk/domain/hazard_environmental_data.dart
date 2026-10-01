import 'hazard_series_utils.dart';
import 'hazard_type.dart';

/// One provider series, with its own unit, timestamps and source.
///
/// [values] keeps the provider's missing entries as null: they are dropped by
/// [samples] together with their timestamp, so a missing hour can never shift
/// the following hours of a window.
class HazardSeries {
  HazardSeries({
    required this.field,
    required this.unit,
    required this.times,
    required this.values,
    required this.source,
  }) : samples = HazardSeriesUtils.align(
          times: times,
          values: values,
        );

  /// Provider field name (`rain`, `soil_moisture_0_to_7cm`, ...).
  final String field;

  /// Unit reported by the provider.
  final String unit;

  final List<DateTime> times;
  final List<double?> values;
  final String source;

  /// Usable samples, sorted by timestamp.
  final List<HazardSample> samples;

  bool get isEmpty => samples.isEmpty;

  int get sampleCount => samples.length;

  DateTime? get lastObservedAt =>
      samples.isEmpty ? null : samples.last.time;
}

/// Everything the live request returned for one hazard.
class HazardLiveData {
  const HazardLiveData({
    required this.hazard,
    required this.series,
    required this.observedAt,
    required this.sources,
    this.missingFields = const <String, String>{},
    this.providerNotes = const <String>[],
  });

  final HazardType hazard;

  /// Series keyed by provider field.
  final Map<String, HazardSeries> series;

  /// Most recent timestamp returned by the providers. It is the real
  /// observation time, not the time the request was made.
  final DateTime observedAt;

  final List<String> sources;

  /// Fields the provider did not return, with the reason.
  final Map<String, String> missingFields;

  /// Facts about the provider data that must reach the evidence (for example
  /// a variable that exists live but has no historical counterpart).
  final List<String> providerNotes;

  HazardSeries? seriesFor(String field) => series[field];

  bool get isEmpty => series.values.every(
        (item) => item.isEmpty,
      );
}
