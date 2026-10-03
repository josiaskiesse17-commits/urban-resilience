import 'hazard_baseline.dart';
import 'hazard_definition.dart';
import 'hazard_environmental_data.dart';
import 'hazard_series_utils.dart';
import 'hazard_variable.dart';
import 'risk_measurement.dart';

/// Result of building the variables of a hazard from live data and the
/// statistical reference.
typedef HazardVariableBuildResult = ({
  List<HazardVariable> variables,
  List<HazardVariableGap> gaps,
});

/// Turns the live series of a hazard into scored variables.
///
/// The same trailing window as the baseline is applied, so the live value and
/// its reference are the same kind of number. A variable whose live window is
/// incomplete, or whose reference could not be computed, becomes a
/// [HazardVariableGap]: it is never replaced by a zero.
class HazardVariableBuilder {
  const HazardVariableBuilder();

  HazardVariableBuildResult build({
    required HazardDefinition definition,
    required HazardLiveData liveData,
    required HazardBaseline baseline,
  }) {
    final variables = <HazardVariable>[];
    final gaps = <HazardVariableGap>[];

    for (final spec in definition.variables) {
      final series = liveData.seriesFor(spec.apiField);

      if (series == null || series.isEmpty) {
        gaps.add(
        HazardVariableGap(
          name: spec.name,
          label: spec.label,
          reason: liveData.missingFields[spec.apiField] ??
              'le fournisseur n’a renvoyé aucune valeur pour '
                  '« ${spec.apiField} » à cet endroit',
        ),
      );

        continue;
      }

      final windowed = HazardSeriesUtils.applyWindow(
        hourly: series.samples,
        window: spec.window,
      );

      final window = HazardSeriesUtils.lastSample(windowed);

      if (window == null) {
        gaps.add(
          HazardVariableGap(
            name: spec.name,
            label: spec.label,
            reason: 'la série de « ${spec.apiField} » comporte une '
                'interruption et aucune fenêtre ${spec.window.label} '
                'complète ne se termine à son dernier horodatage',
          ),
        );

        continue;
      }

      if (spec.informational) {
        variables.add(
          HazardVariable(
            name: spec.name,
            label: spec.label,
            value: window.value,
            unit: series.unit.isEmpty ? spec.unit : series.unit,
            measurementPeriod: spec.window.label,
            weight: spec.weight,
            source: series.source,
            observedAt: window.time,
            isDerived: spec.derived,
            derivationNote: spec.derivationNote,
            informational: true,
          ),
        );

        continue;
      }

      final reference = baseline.variableFor(spec.name);

      if (reference == null) {
        gaps.add(
          HazardVariableGap(
            name: spec.name,
            label: spec.label,
            reason: 'aucune référence statistique n’a pu être construite '
                'à partir de la série historique de « ${spec.apiField} » '
                'pour cet endroit',
          ),
        );

        continue;
      }

      final slice = reference.sliceFor(window.time);

      variables.add(
        HazardVariable.fromDistribution(
          name: spec.name,
          label: spec.label,
          value: window.value,
          unit: series.unit.isEmpty ? spec.unit : series.unit,
          measurementPeriod: spec.window.label,
          weight: spec.weight,
          distribution: slice.distribution,
          centralPercentile: spec.centralPercentile,
          outerPercentile: spec.outerPercentile,
          referenceLabel: _referenceLabel(
            baseline: baseline,
            reference: reference,
            slice: slice,
          ),
          referenceType: RiskReferenceType.historicalMedian,
          inverted: spec.inverted,
          source: series.source,
          observedAt: window.time,
          isDerived: spec.derived,
          derivationNote: spec.derivationNote,
        ),
      );
    }

    return (
      variables: variables,
      gaps: gaps,
    );
  }

  String _referenceLabel({
    required HazardBaseline baseline,
    required HazardBaselineVariable reference,
    required HazardBaselineSlice slice,
  }) {
    final month = slice.month;

    final scope = slice.usedSeasonalBucket && month != null
        ? 'du mois de ${_monthNames[month - 1]}'
        : 'de toute la période de référence';

    return 'Médiane $scope, '
        '${_formatDate(baseline.referencePeriodStart)} – '
        '${_formatDate(baseline.referencePeriodEnd)} '
        'référence ${baseline.source} '
        '(${slice.distribution.sampleCount} échantillons de la fenêtre '
        '${reference.window.label})';
  }
}

const List<String> _monthNames = <String>[
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}
