import 'hazard_baseline.dart';
import 'hazard_definition.dart';
import 'hazard_historical_data.dart';
import 'hazard_series_utils.dart';
import 'historical_distribution.dart';











class HazardBaselineCalculator {
  const HazardBaselineCalculator();

  HazardBaseline calculate({
    required HazardDefinition definition,
    required HazardHistoricalData data,
    DateTime? generatedAt,
    int minimumSeasonalSamples =
        HazardBaselineVariable.minimumSeasonalSamples,
  }) {
    final variables = <String, HazardBaselineVariable>{};
    final notes = <String>[];

    for (final spec in definition.variables) {
      if (!spec.hasHistoricalReference) {
        notes.add(
          'The historical source of this location does not provide '
          '`${spec.apiField}`, so `${spec.name}` has no statistical '
          'reference and is reported as evidence only.',
        );

        continue;
      }

      final series = data.seriesFor(spec.apiField);

      if (series == null || series.isEmpty) {
        notes.add(
          'The historical source returned no usable series for '
          '`${spec.apiField}`, so `${spec.name}` has no statistical '
          'reference.',
        );

        continue;
      }

      final windowed = HazardSeriesUtils.applyWindow(
        hourly: series.samples,
        window: spec.window,
      );

      if (windowed.isEmpty) {
        notes.add(
          'The historical series of `${spec.apiField}` has no contiguous '
          '${spec.window.label} window, so `${spec.name}` has no '
          'statistical reference.',
        );

        continue;
      }

      final byMonth = <int, HistoricalDistribution>{};

      final buckets = HazardSeriesUtils.byMonth(windowed);

      for (final bucket in buckets.entries) {
        if (bucket.value.length < minimumSeasonalSamples) {
          continue;
        }

        byMonth[bucket.key] = HistoricalDistribution(
          bucket.value,
        );
      }

      final seasonal =
          definition.seasonalReference && byMonth.isNotEmpty;

      if (definition.seasonalReference && !seasonal) {
        notes.add(
          'No calendar month of the reference period has enough samples '
          'for `${spec.name}`; its whole-period statistics are used '
          'instead.',
        );
      }

      variables[spec.name] = HazardBaselineVariable(
        name: spec.name,
        unit: spec.unit,
        window: spec.window,
        overall: HistoricalDistribution(
          windowed
              .map((sample) => sample.value)
              .toList(growable: false),
        ),
        byMonth: byMonth,
        seasonal: seasonal,
      );
    }

    return HazardBaseline(
      hazard: definition.hazard,
      variables: variables,
      referencePeriodStart: data.referencePeriodStart,
      referencePeriodEnd: data.referencePeriodEnd,
      generatedAt: generatedAt ?? DateTime.now().toUtc(),
      source: data.source,
      notes: notes,
    );
  }
}
