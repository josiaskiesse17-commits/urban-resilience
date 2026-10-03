import 'hazard_series_utils.dart';
import 'hazard_type.dart';

enum HazardVariableSource {
  openMeteoWeather(label: 'Open-Meteo Weather API'),

  openMeteoFlood(label: 'Open-Meteo Global Flood API / GloFAS');

  const HazardVariableSource({required this.label});

  final String label;
}

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

  final String name;

  final String label;

  final String apiField;

  final HazardVariableSource source;

  final HazardWindow window;

  final String unit;

  final double weight;

  final bool inverted;

  final bool informational;

  final bool derived;

  final String? derivationNote;

  final bool hasHistoricalReference;

  double get centralPercentile => 50;

  double get outerPercentile => inverted ? 5 : 95;
}

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

  final String primaryFactorLabel;

  final String description;

  final List<HazardVariableSpec> variables;

  final bool seasonalReference;

  final List<String> limitations;

  final bool legacyPipeline;

  List<HazardVariableSpec> get scoredVariables => variables
      .where((variable) => !variable.informational)
      .toList(growable: false);

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
