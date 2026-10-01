import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/risk_repository.dart';
import '../domain/hazard_risk_id.dart';
import '../domain/hazard_type.dart';
import '../domain/risk_analysis.dart';
import '../domain/risk_factor_score.dart';
import '../domain/risk_measurement.dart';
import '../domain/risk_measurement_label.dart';
import '../domain/risk_result.dart';
import '../domain/risk_result_freshness.dart';
import '../domain/risk_simulation.dart';
import '../domain/risk_zone.dart';
import 'providers/risk_ai_providers.dart';
import 'providers/risk_live_providers.dart';
import 'widgets/risk_exposure_card.dart';

class RiskDetailsScreen extends ConsumerStatefulWidget {
  final String riskId;

  const RiskDetailsScreen({
    super.key,
    required this.riskId,
  });

  @override
  ConsumerState<RiskDetailsScreen> createState() =>
      _RiskDetailsScreenState();
}

class _RiskDetailsScreenState
    extends ConsumerState<RiskDetailsScreen> {
  RiskAnalysis? _analysis;
  Object? _analysisError;
  bool _isAnalyzing = false;

  /// Version of the result that was already sent to the AI analyst.
  ///
  /// It is set *before* the request starts and is deliberately not reset when
  /// the request fails, so neither a rebuild nor a failed request can trigger
  /// another automatic analysis. Retrying is an explicit user action.
  String? _analyzedRiskVersion;

  bool _isUpdatingRisk = false;
  Object? _updateError;

  /// Risk id that already went through the automatic
  /// "load the stored result or generate it" step, so a rebuild never starts
  /// another run.
  String? _updateAttemptedForId;

  /// Hazard inspected on this screen. It starts from the hazard carried by
  /// the route id (bare ids are flooding) and can be switched with the
  /// selector, which loads the document of that hazard for the same zone.
  late HazardType _selectedHazard;

  /// Hypothetical values of the What-If section, keyed by measurement name.
  ///
  /// They live only in this widget: a simulation never replaces a risk
  /// result, never triggers a request and is dropped as soon as the hazard or
  /// the zone changes.
  final Map<String, double> _simulatedValues = <String, double>{};

  /// What-If engine. It is pure computation, so running a simulation cannot
  /// touch the network, Firestore or the AI analyst.
  static const RiskSimulationService _simulationService =
      RiskSimulationService();

  /// `risk_results` document of the zone and the selected hazard.
  String get _riskId => HazardRiskId.forZone(
        zoneId: HazardRiskId.zoneIdOf(widget.riskId),
        hazard: _selectedHazard,
      );

  @override
  void initState() {
    super.initState();
    _selectedHazard = HazardRiskId.hazardOf(widget.riskId);
  }

  String _riskVersion(RiskResult riskResult) {
    return '${riskResult.id}@'
        '${riskResult.updatedAt.toUtc().toIso8601String()}';
  }

  /// Target used to rerun the pipeline: the zone catalog when the zone is
  /// known, otherwise the coordinates already stored in the result.
  ///
  /// The hazard suffix of the risk id (`zone-masina--heat`) is removed first
  /// so the catalog entry and the generator always receive the bare zone id
  /// and rebuild the very same document.
  RiskZoneTarget _targetFor(RiskResult riskResult) {
    final zoneId = HazardRiskId.zoneIdOf(riskResult.id);

    return RiskZoneCatalog.byId(zoneId) ??
        (
          id: zoneId,
          name: riskResult.locationName,
          latitude: riskResult.latitude,
          longitude: riskResult.longitude,
        );
  }

  /// Runs the shared Risk Intelligence pipeline once and reloads the result.
  Future<bool> _generate(RiskZoneTarget zone) async {
    try {
      await ref.read(zoneHazardRiskGeneratorProvider)(
        zone,
        _selectedHazard,
      );

      if (!mounted) {
        return true;
      }

      ref.invalidate(
        riskResultProvider(_riskId),
      );

      setState(() {
        _isUpdatingRisk = false;
        _updateError = null;
      });

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _isUpdatingRisk = false;
        _updateError = error;
      });

      return false;
    }
  }

  /// Shows the stored result when it is usable, and generates it when it is
  /// missing or older than [RiskResultFreshness.maxAge].
  ///
  /// The user never has to run a "generation" step: selecting a zone is
  /// enough. It runs at most once per risk id for the lifetime of the screen.
  Future<void> _ensureFreshRisk(RiskResult? stored) async {
    if (_isUpdatingRisk ||
        _updateAttemptedForId == _riskId) {
      return;
    }

    final zone = stored == null
        ? RiskZoneCatalog.byId(
            HazardRiskId.zoneIdOf(widget.riskId),
          )
        : _targetFor(stored);

    if (zone == null) {
      setState(() {
        _updateAttemptedForId = _riskId;
        _updateError = StateError(
          'No coordinates are known for "$_riskId", '
          'so its risk cannot be calculated.',
        );
      });

      return;
    }

    setState(() {
      _updateAttemptedForId = _riskId;
      _isUpdatingRisk = true;
      _updateError = null;
    });

    await _generate(zone);
  }

  Future<void> _analyzeRisk(RiskResult riskResult) async {
    final version = _riskVersion(riskResult);

    if (_isAnalyzing || _analyzedRiskVersion == version) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _analysis = null;
      _analyzedRiskVersion = version;
    });

    try {
      final analysis = await ref
          .read(riskAnalystProvider)
          .analyze(riskResult);

      if (!mounted) {
        return;
      }

      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _analysisError = error;
        _isAnalyzing = false;
      });
    }
  }

  /// Explicit recalculation requested by the user (button, pull-to-refresh).
  Future<void> _refreshLiveRisk(RiskResult stored) async {
    if (_isUpdatingRisk) {
      return;
    }

    setState(() {
      _isUpdatingRisk = true;
      _updateError = null;
      _updateAttemptedForId = _riskId;
      _analyzedRiskVersion = null;
      _analysis = null;
      _analysisError = null;
    });

    final generated = await _generate(_targetFor(stored));

    if (!mounted || !generated) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Risk result recalculated and saved.',
        ),
      ),
    );
  }

  Color _riskColor(
    BuildContext context,
    RiskLevel riskLevel,
  ) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Colors.green;

      case RiskLevel.medium:
        return Colors.amber.shade700;

      case RiskLevel.high:
        return Colors.orange.shade800;

      case RiskLevel.critical:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskAsync =
        ref.watch(riskResultProvider(_riskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
      ),
      body: riskAsync.when(
        loading: () => _buildPreparing(context),
        error: (error, stackTrace) =>
            _buildLoadError(context, error),
        data: (riskResult) {
          if (RiskResultFreshness.needsUpdate(riskResult) &&
              !_isUpdatingRisk &&
              _updateAttemptedForId != _riskId) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) {
                _ensureFreshRisk(riskResult);
              }
            });
          }

          if (riskResult == null) {
            return _buildPreparing(context);
          }

          if (!_isAnalyzing &&
              !_isUpdatingRisk &&
              _analyzedRiskVersion !=
                  _riskVersion(riskResult)) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) {
                _analyzeRisk(riskResult);
              }
            });
          }

          return _buildRiskContent(
            context,
            riskResult,
          );
        },
      ),
    );
  }

  /// Hazard selector of the zone: every hazard reads and writes its own
  /// `risk_results` document, so switching never overwrites the assessment
  /// of another hazard.
  Widget _buildHazardSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HazardType.values
              .map(
                (hazard) => ChoiceChip(
                  label: Text(hazard.label),
                  selected: hazard == _selectedHazard,
                  onSelected: (selected) {
                    if (!selected ||
                        hazard == _selectedHazard) {
                      return;
                    }

                    setState(() {
                      _selectedHazard = hazard;
                      _updateAttemptedForId = null;
                      _updateError = null;
                      _isUpdatingRisk = false;
                      _isAnalyzing = false;
                      _analyzedRiskVersion = null;
                      _analysis = null;
                      _analysisError = null;
                      _simulatedValues.clear();
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildRiskContent(
    BuildContext context,
    RiskResult riskResult,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshLiveRisk(riskResult),
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                _buildHazardSelector(context),
                const SizedBox(height: 16),
                _buildUpdateStatus(
                  context,
                  riskResult,
                ),
                _buildRiskSummary(
                  context,
                  riskResult,
                ),
                const SizedBox(height: 16),
                RiskExposureCard(
                  zoneId: HazardRiskId.zoneIdOf(
                    widget.riskId,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFactorsCard(
                  context,
                  riskResult,
                ),
                const SizedBox(height: 16),
                _buildEvidenceCard(
                  context,
                  riskResult,
                ),
                const SizedBox(height: 16),
                _buildRefreshCard(
                  context,
                  riskResult,
                ),
                const SizedBox(height: 16),
                _buildAiCard(
                  context,
                  riskResult,
                ),
                const SizedBox(height: 16),
                _buildWhatIfCard(
                  context,
                  riskResult,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reports what the screen is doing on its own (first generation or stale
  /// refresh) and surfaces failures that need a user decision.
  Widget _buildUpdateStatus(
    BuildContext context,
    RiskResult riskResult,
  ) {
    if (_isUpdatingRisk) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: ListTile(
            leading: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            title: const Text(
              'Refreshing the live assessment...',
            ),
            subtitle: Text(
              'Recalculating with the latest rainfall, river and '
              'exposure data. The stored result stays visible until '
              'the new one is saved.',
            ),
          ),
        ),
      );
    }

    final updateError = _updateError;

    if (updateError == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'The live assessment could not be updated.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$updateError',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The values below are the last successfully stored '
                'result for this zone.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    _refreshLiveRisk(riskResult),
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown while the stored result is read, and while the first assessment of
  /// a zone is generated. Nothing has to be pressed for this to happen.
  Widget _buildPreparing(BuildContext context) {
    final theme = Theme.of(context);
    final zone = RiskZoneCatalog.byId(
      HazardRiskId.zoneIdOf(widget.riskId),
    );
    final updateError = _updateError;

    if (updateError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_off,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No risk assessment could be loaded for this zone.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$updateError',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _updateAttemptedForId = null;
                      _updateError = null;
                    });

                    _ensureFreshRisk(null);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              zone == null
                  ? 'Preparing the assessment for '
                      '"$_riskId"...'
                  : 'Preparing the assessment for '
                      '${zone.name}...',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historical rainfall and river baseline, then the '
              'current environmental data. The first run of a zone '
              'can take a few seconds.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSummary(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);
    final riskColor = _riskColor(
      context,
      riskResult.riskLevel,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              riskResult.locationName,
              style:
                  theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              riskResult.hazardType,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withAlpha(30),
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                  child: Text(
                    riskResult.riskLevel.name
                        .toUpperCase(),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${riskResult.riskScore.toStringAsFixed(0)}/100',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Updated ${_formatDateTime(riskResult.updatedAt)}',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'Live Risk',
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The assessment is loaded automatically when '
              'the zone is opened and kept for '
              '${RiskResultFreshness.maxAge.inHours} hours '
              'before it is refreshed again. Recalculate it '
              'now to use the latest environmental data.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isUpdatingRisk
                  ? null
                  : () => _refreshLiveRisk(
                        riskResult,
                      ),
              icon: _isUpdatingRisk
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                    ),
              label: Text(
                _isUpdatingRisk
                    ? 'Recalculating...'
                    : 'Recalculate now',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historical reference: '
              '${_formatDate(RiskZoneCatalog.historicalBaselineStart)}'
              ' – '
              '${_formatDate(RiskZoneCatalog.historicalBaselineEnd)}',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stored as risk_results/${riskResult.id}',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);
    final factors = riskResult.factors;
    final entries = factors.entries;
    final rows = <Widget>[];

    if (entries.isEmpty) {
      // Document written before the factor breakdown existed: only the four
      // legacy scores are stored, so they are the only rows that can be shown.
      rows.addAll(<Widget>[
        _buildFactorRow(
          context,
          factors.primaryFactorLabel,
          factors.rainfall,
        ),
        _buildFactorRow(
          context,
          'Geographic vulnerability',
          factors.geographicVulnerability,
        ),
        _buildFactorRow(
          context,
          'Historical exposure',
          factors.historicalExposure,
        ),
        _buildFactorRow(
          context,
          'Current observations',
          factors.currentObservations,
        ),
      ]);
    } else {
      for (final entry in entries) {
        final score = entry.score;

        rows.add(
          score == null
              ? _buildUnavailableFactorRow(context, entry)
              : _buildFactorRow(context, entry.label, score),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Factors',
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Each bar is one input this assessment really used, scored '
              'from 0 to 100 against the reference of the same location. '
              'A factor that could not be measured is reported as '
              'unavailable, never as zero.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              rows[index],
            ],
          ],
        ),
      ),
    );
  }

  /// Factor the assessment could not score. It is shown as unavailable with
  /// the reason, so a missing measurement is never read as a safe zero.
  Widget _buildUnavailableFactorRow(
    BuildContext context,
    RiskFactorScore entry,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              'Unavailable',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entry.unavailableReason ??
              'No measurement was available for this factor, so it is '
                  'excluded from the score.',
          style:
              theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFactorRow(
    BuildContext context,
    String label,
    double value,
  ) {
    final theme = Theme.of(context);
    final normalized =
        value.clamp(0.0, 100.0) / 100.0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style:
                    theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}/100',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: normalized,
          minHeight: 8,
          borderRadius:
              BorderRadius.circular(999),
        ),
      ],
    );
  }

  Widget _buildEvidenceCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Evidence',
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${riskResult.evidence.observationCount} '
              'observations received • '
              '${riskResult.evidence.confirmedObservationCount} '
              'confirmed',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Collected ${_formatDateTime(riskResult.evidence.collectedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...riskResult.evidence.measurements.map(
              (measurement) => _buildMeasurement(
                context,
                measurement,
              ),
            ),
            if (riskResult
                .evidence
                .qualitativeIndicators
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Indicators',
                style:
                    theme.textTheme.titleMedium?.copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...riskResult
                  .evidence
                  .qualitativeIndicators
                  .map(
                (indicator) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding:
                            EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(indicator),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurement(
    BuildContext context,
    RiskMeasurement measurement,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                theme.colorScheme.outlineVariant,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              RiskMeasurementLabel.of(
                name: measurement.name,
                measurementPeriod:
                    measurement.measurementPeriod,
                unit: measurement.unit,
              ),
              style:
                  theme.textTheme.titleSmall?.copyWith(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${measurement.value.toStringAsFixed(2)} '
              '${measurement.unit}',
            ),
            if (measurement.referenceValue != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reference: '
                '${measurement.referenceValue!.toStringAsFixed(2)}'
                '${measurement.referenceUnit == null ? '' : ' ${measurement.referenceUnit}'}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (measurement.referenceLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                measurement.referenceLabel!,
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (measurement.isDerived &&
                measurement.derivationNote != null) ...[
              const SizedBox(height: 4),
              Text(
                'Derived value: ${measurement.derivationNote}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (measurement.source != null) ...[
              const SizedBox(height: 4),
              Text(
                'Source: ${measurement.source}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (measurement.observedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Observed '
                '${_formatDateTime(measurement.observedAt!)}',
                style:
                    theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'AI Risk Analyst',
              style:
                  theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The AI interprets this stored risk result, '
              'its measurements and its evidence. It runs '
              'once per saved result: use Retry if the '
              'request failed.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (_isAnalyzing)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (_analysisError != null)
              _buildAnalysisError(
                context,
                riskResult,
              )
            else if (_analysis != null)
              _buildAnalysis(
                context,
                _analysis!,
              )
            else
              FilledButton.icon(
                onPressed: () =>
                    _retryAnalysis(
                  riskResult,
                ),
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                label:
                    const Text('Analyze risk'),
              ),
          ],
        ),
      ),
    );
  }

  /// Deterministic What-If section.
  ///
  /// It re-runs the shared risk engine with the hypothetical values selected
  /// here and reports the simulated outcome inside this card only: no AI
  /// request, no data fetch, and the stored assessment, factors, evidence and
  /// AI explanation above stay exactly as they are.
  Widget _buildWhatIfCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);
    final model = _simulationService.modelFrom(riskResult);
    final variables =
        model?.variables ?? const <RiskSimulationVariable>[];
    final values = <String, double>{
      for (final variable in variables)
        variable.name:
            _simulatedValues[variable.name] ?? variable.currentValue,
    };

    final changed = model == null
        ? false
        : model.adjustable.any(
            (variable) =>
                (values[variable.name]! - variable.currentValue).abs() >
                0.0001,
          );

    final outcome = model != null && model.isSimulatable
        ? _simulationService.simulate(
            model: model,
            values: values,
          )
        : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'What-If Scenario',
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Simulate what would happen if the conditions of this '
              'hazard changed. The simulated score is computed by the same '
              'risk engine as the assessment above, against the same '
              'reference values. This is a simulation inside this section '
              'only: not a forecast and not a warning. It never changes the '
              'stored result, the risk factors, the evidence or the AI '
              'explanation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (model == null)
              Text(
                'The hazard of this stored assessment could not be '
                'identified, so no simulation can be built for it.',
              )
            else if (!model.isSimulatable)
              Text(
                model.unavailableReason ??
                    'This assessment has no adjustable input.',
              )
            else ...[
              ..._buildSimulationControls(
                context,
                model,
                values,
              ),
              if (model.fixed.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Not adjustable here: '
                  '${model.fixed.map((variable) => variable.label).join(', ')}. '
                  'These variables are reported as evidence only and are '
                  'not part of the score.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (!changed)
                Text(
                  'Move a control to simulate a different situation. The '
                  'measured values are used until then.',
                  style: theme.textTheme.bodyMedium,
                )
              else if (outcome != null)
                _buildSimulationResult(
                  context,
                  model,
                  outcome,
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: changed
                    ? () => setState(
                          _simulatedValues.clear,
                        )
                    : null,
                icon: const Icon(Icons.restart_alt),
                label:
                    const Text('Back to the measured values'),
              ),
              if (model.factorBreakdownMissing) ...[
                const SizedBox(height: 4),
                Text(
                  'This stored assessment was written before the factor '
                  'breakdown existed: only its environmental variables are '
                  'simulated. Recalculate it to simulate the exposure '
                  'factors as well.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (model.limitations.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'What this model does not include: '
                  '${model.limitations.join(' ')}',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSimulationControls(
    BuildContext context,
    RiskSimulationModel model,
    Map<String, double> values,
  ) {
    return model.adjustable
        .map(
          (variable) => _buildSimulationControl(
            context,
            variable,
            values[variable.name]!,
          ),
        )
        .toList(growable: false);
  }

  /// One slider per adjustable input of the hazard. The bounds come from the
  /// statistical reference of the stored assessment, so a simulation can only
  /// move inside a meaningful range.
  Widget _buildSimulationControl(
    BuildContext context,
    RiskSimulationVariable variable,
    double value,
  ) {
    final theme = Theme.of(context);
    final lower = variable.lowerBound;
    final upper = variable.upperBound;
    final current = value.clamp(lower, upper);
    final score = variable.scoreFor(current);
    final reference = variable.referenceValue;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                variable.label,
                style:
                    theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_formatValue(current)} '
              '${variable.unit}',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Slider(
          value: current,
          min: lower,
          max: upper,
          divisions: 60,
          label: '${_formatValue(current)} '
              '${variable.unit}',
          onChanged: (next) {
            setState(() {
              _simulatedValues[variable.name] = next;
            });
          },
        ),
        Text(
          'Measured ${_formatValue(variable.currentValue)} '
          '${variable.unit}'
          '${reference == null ? '' : ' · reference ${_formatValue(reference)} ${variable.unit}'}'
          ' · factor score '
          '${score == null ? 'unavailable' : '${score.toStringAsFixed(0)}/100'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Outcome of a simulation, shown inside the What-If section only.
  Widget _buildSimulationResult(
    BuildContext context,
    RiskSimulationModel model,
    RiskSimulationOutcome outcome,
  ) {
    final theme = Theme.of(context);
    final levelColor = _riskColor(context, outcome.level);
    final difference = outcome.difference;

    final differenceLabel = difference.abs() < 0.05
        ? 'same score as the stored assessment'
        : '${difference > 0 ? '+' : ''}'
            '${difference.toStringAsFixed(1)} points versus the '
            'stored assessment';

    final changedFactors = <String>[];

    for (final variable in model.variables) {
      final value = outcome.values[variable.name] ?? variable.currentValue;
      final simulated = variable.scoreFor(value);
      final measured = variable.scoreFor(variable.currentValue);

      if (simulated == null || measured == null) {
        continue;
      }

      if ((simulated - measured).abs() < 0.5) {
        continue;
      }

      changedFactors.add(
        '${variable.label}: '
        '${measured.toStringAsFixed(0)} → '
        '${simulated.toStringAsFixed(0)}/100',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(18),
        border: Border.all(
          color: levelColor.withAlpha(90),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Simulated result',
            style:
                theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment:
                WrapCrossAlignment.center,
            children: [
              Text(
                '${outcome.score.toStringAsFixed(0)}/100',
                style:
                    theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(30),
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  outcome.level.name.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$differenceLabel · stored assessment '
            '${model.currentScore.toStringAsFixed(0)}/100 '
            '(${model.currentLevel.name.toUpperCase()}).',
          ),
          if (outcome.levelChanged) ...[
            const SizedBox(height: 6),
            Text(
              'Under these hypothetical values the '
              '${model.hazard.riskNoun} reaches the '
              '${outcome.level.name.toUpperCase()} level, while the stored '
              'assessment is ${model.currentLevel.name.toUpperCase()}.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: levelColor,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Factor scores under the simulated values',
            style:
                theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (changedFactors.isEmpty)
            const Text(
              'No factor score changed with these values.',
            )
          else
            ...changedFactors.map(
              (line) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 4),
                child: Text('• $line'),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Simulated only: this outcome is not stored, is not a forecast '
            'and does not change the assessment, the factors, the evidence '
            'or the AI explanation above.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    final magnitude = value.abs();

    if (magnitude >= 100) {
      return value.toStringAsFixed(0);
    }

    if (magnitude >= 10) {
      return value.toStringAsFixed(1);
    }

    return value.toStringAsFixed(2);
  }

  Widget _buildAnalysis(
    BuildContext context,
    RiskAnalysis analysis,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summary',
          style:
              theme.textTheme.titleMedium?.copyWith(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(analysis.summary),
        const SizedBox(height: 20),
        Text(
          'Why?',
          style:
              theme.textTheme.titleMedium?.copyWith(
            fontWeight:
                FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(analysis.explanation),
        if (analysis.mainFactors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Main factors',
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...analysis.mainFactors.map(
            (factor) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(factor),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (analysis.recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Recommendations',
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...analysis.recommendations.map(
            (recommendation) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recommendation,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalysisError(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Text(
          'The AI analysis could not be generated.',
          style:
              theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _analysisError.toString(),
          style:
              theme.textTheme.bodySmall?.copyWith(
            color:
                theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The app does not retry on its own. Use Retry '
          'when the AI service is reachable again.',
          style:
              theme.textTheme.bodySmall?.copyWith(
            color:
                theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              _retryAnalysis(
            riskResult,
          ),
          icon:
              const Icon(Icons.refresh),
          label:
              const Text('Retry AI analysis'),
        ),
      ],
    );
  }

  Widget _buildLoadError(
    BuildContext context,
    Object error,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load this risk result.',
              style:
                  theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign:
                  TextAlign.center,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(
                  riskResultProvider(
                    _riskId,
                  ),
                );
              },
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // The old "Risk result not found." state was replaced by the automatic
  // load-or-generate flow handled by _buildPreparing().
  void _retryAnalysis(
    RiskResult riskResult,
  ) {
    setState(() {
      _analyzedRiskVersion = null;
      _analysis = null;
      _analysisError = null;
      _isAnalyzing = false;
    });

    _analyzeRisk(riskResult);
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    return '${local.year}-'
        '${twoDigits(local.month)}-'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}