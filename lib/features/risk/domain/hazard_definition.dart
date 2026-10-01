import 'hazard_series_utils.dart';
import 'hazard_type.dart';

/// Provider of a hazard variable.
enum HazardVariableSource {
  /// `api.open-meteo.com/v1/forecast` for the live value and
  /// `archive-api.open-meteo.com/v1/archive` (ERA5) for the history.
  openMeteoWeather(label: 'Open-Meteo Weather API'),

  /// `flood-api.open-meteo.com/v1/flood` (GloFAS river discharge).
  openMeteoFlood(label: 'Open-Meteo Global Flood API / GloFAS');

  const HazardVariableSource({
    required this.label,
  });

  final String label;
}

/// One variable of a hazard model.
///
/// [apiField] is the exact provider field name, so the request that feeds the
/// hazard is derived from this catalog instead of being duplicated in the
/// data source.
class HazardVariableSpec {
  const HazardVariableSpec({
    required this.name,
    required this.label,
    required this.apiField,
    required this.source,
    required this.window,
    required this.unit,
    required this.weight,
    this.inverted = false,
    this.informational = false,
    this.derived = false,
    this.derivationNote,
    this.hasHistoricalReference = true,
  });

  /// Name written to the evidence.
  final String name;

  /// Human readable label.
  final String label;

  /// Provider field the series is read from.
  final String apiField;

  final HazardVariableSource source;

  /// Trailing window the variable is derived over.
  final HazardWindow window;

  final String unit;

  /// Nominal weight inside the hazard score.
  final double weight;

  /// True when a low value is the risk.
  final bool inverted;

  /// True when the variable is reported in the evidence but not scored.
  final bool informational;

  /// True when the value is computed by the app from the series.
  final bool derived;

  final String? derivationNote;

  /// False for a variable the historical provider cannot return (CAPE is not
  /// part of ERA5), which therefore gets no statistical reference.
  final bool hasHistoricalReference;

  /// Percentile of the reference distribution used as central reference.
  double get centralPercentile => 50;

  /// Percentile of the reference distribution that bounds the score.
  double get outerPercentile => inverted ? 5 : 95;
}

/// Declarative definition of one hazard.
class HazardDefinition {
  const HazardDefinition({
    required this.hazard,
    required this.primaryFactorLabel,
    required this.description,
    required this.variables,
    this.seasonalReference = true,
    this.limitations = const <String>[],
    this.legacyPipeline = false,
  });

  final HazardType hazard;

  /// Label of the first risk factor in the stored result.
  final String primaryFactorLabel;

  final String description;

  final List<HazardVariableSpec> variables;

  /// True when the statistical reference is taken from the same calendar
  /// month of the reference period instead of from the whole period. All the
  /// hazards added in this work use it: in a tropical climate the same
  /// rainfall, soil-moisture or temperature value does not mean the same
  /// thing in the rainy season and in the dry season.
  final bool seasonalReference;

  /// What the model cannot assess with the data available today. Reported to
  /// the user instead of being hidden.
  final List<String> limitations;

  /// True when the hazard is assessed by its own pipeline (flooding) and the
  /// generic engine must not score its variables.
  final bool legacyPipeline;

  List<HazardVariableSpec> get scoredVariables => variables
      .where((variable) => !variable.informational)
      .toList(growable: false);

  /// Provider fields the live request must ask for.
  List<String> get liveApiFields {
    final fields = <String>[];

    for (final variable in variables) {
      if (variable.source == HazardVariableSource.openMeteoFlood) {
        continue;
      }

      if (!fields.contains(variable.apiField)) {
        fields.add(variable.apiField);
      }
    }

    return fields;
  }

  /// Provider fields the historical request must ask for.
  List<String> get historicalApiFields {
    final fields = <String>[];

    for (final variable in variables) {
      if (!variable.hasHistoricalReference) {
        continue;
      }

      if (variable.source == HazardVariableSource.openMeteoFlood) {
        continue;
      }

      if (!fields.contains(variable.apiField)) {
        fields.add(variable.apiField);
      }
    }

    return fields;
  }

  /// Days of hourly live data needed for the longest window of the hazard.
  int get liveLookbackDays {
    var days = 1;

    for (final variable in variables) {
      final required = variable.window.requiredLookbackDays;

      if (required > days) {
        days = required;
      }
    }

    return days;
  }

  double get totalScoredWeight {
    var total = 0.0;

    for (final variable in scoredVariables) {
      total += variable.weight;
    }

    return total;
  }
}
