import 'hazard_series_utils.dart';
import 'hazard_type.dart';






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

  
  final String field;

  
  final String unit;

  final List<DateTime> times;
  final List<double?> values;
  final String source;

  
  final List<HazardSample> samples;

  bool get isEmpty => samples.isEmpty;

  int get sampleCount => samples.length;

  DateTime? get lastObservedAt =>
      samples.isEmpty ? null : samples.last.time;
}


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

  
  final Map<String, HazardSeries> series;

  
  
  final DateTime observedAt;

  final List<String> sources;

  
  final Map<String, String> missingFields;

  
  
  final List<String> providerNotes;

  HazardSeries? seriesFor(String field) => series[field];

  bool get isEmpty => series.values.every(
        (item) => item.isEmpty,
      );
}
