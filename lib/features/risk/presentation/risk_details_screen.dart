import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/core/theme/app_palette.dart';
import 'package:urban_resilience/features/location/presentation/selected_place_provider.dart';

import '../data/risk_repository.dart';
import '../domain/hazard_risk_id.dart';
import '../domain/hazard_type.dart';
import '../domain/risk_analysis.dart';
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

  static const _cardShadow = BoxShadow(
    color: Color.fromRGBO(16, 42, 49, 0.08),
    blurRadius: 20,
    offset: Offset(0, 6),
  );

  @override
  ConsumerState<RiskDetailsScreen> createState() =>
      _RiskDetailsScreenState();
}

class _RiskDetailsScreenState
    extends ConsumerState<RiskDetailsScreen> {
  RiskAnalysis? _analysis;
  Object? _analysisError;
  bool _isAnalyzing = false;

  String? _analyzedRiskVersion;

  bool _isUpdatingRisk = false;
  Object? _updateError;

  String? _updateAttemptedForId;

  late HazardType _selectedHazard;

  final Map<String, double> _simulatedValues =
      <String, double>{};

  static const RiskSimulationService _simulationService =
      RiskSimulationService();

  String get _riskId => HazardRiskId.forZone(
        zoneId: HazardRiskId.zoneIdOf(widget.riskId),
        hazard: _selectedHazard,
      );

  @override
  void initState() {
    super.initState();
    _selectedHazard =
        HazardRiskId.hazardOf(widget.riskId);
  }

  String _riskVersion(RiskResult riskResult) {
    return '${riskResult.id}@'
        '${riskResult.updatedAt.toUtc().toIso8601String()}';
  }

  RiskZoneTarget _targetFor(
    RiskResult riskResult,
  ) {
    final zoneId = HazardRiskId.zoneIdOf(
      riskResult.id,
    );

    return RiskZoneCatalog.byId(zoneId) ??
        (
          id: zoneId,
          name: riskResult.locationName,
          latitude: riskResult.latitude,
          longitude: riskResult.longitude,
        );
  }

  Future<bool> _generate(
    RiskZoneTarget zone,
  ) async {
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

  Future<void> _ensureFreshRisk(
    RiskResult? stored,
  ) async {
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
      if (!mounted) {
        return;
      }

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

  Future<void> _analyzeRisk(
    RiskResult riskResult,
  ) async {
    final version = _riskVersion(riskResult);

    if (_isAnalyzing ||
        _analyzedRiskVersion == version) {
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

  Future<void> _refreshLiveRisk(
    RiskResult stored,
  ) async {
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

    final generated =
        await _generate(_targetFor(stored));

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

  @override
  Widget build(BuildContext context) {
    final place = ref.watch(
      selectedPlaceProvider,
    );

    final riskAsync =
        ref.watch(riskResultProvider(_riskId));

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: riskAsync.when(
        loading: () => _buildPreparing(context),
        error: (error, stackTrace) =>
            _buildLoadError(
          context,
          error,
        ),
        data: (riskResult) {
          if (RiskResultFreshness.needsUpdate(
                riskResult,
              ) &&
              !_isUpdatingRisk &&
              _updateAttemptedForId != _riskId) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) {
                _ensureFreshRisk(
                  riskResult,
                );
              }
            });
          }

          if (riskResult == null) {
            return _buildPreparing(
              context,
            );
          }

          if (!_isAnalyzing &&
              !_isUpdatingRisk &&
              _analyzedRiskVersion !=
                  _riskVersion(riskResult)) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) {
              if (mounted) {
                _analyzeRisk(
                  riskResult,
                );
              }
            });
          }

          final locationLabel =
              place?.label ??
                  riskResult.locationName;

          return _buildRiskContent(
            context,
            riskResult,
            locationLabel,
          );
        },
      ),
    );
  }

  Widget _buildRiskContent(
    BuildContext context,
    RiskResult riskResult,
    String locationLabel,
  ) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(
            context,
            riskResult,
            locationLabel,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  _refreshLiveRisk(
                riskResult,
              ),
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
                children: [
                  _buildSummaryCard(
                    context,
                    riskResult,
                  ),
                  const SizedBox(height: 12),
                  _buildWhyCard(
                    context,
                    riskResult,
                  ),
                  const SizedBox(height: 12),
                  _buildFactorsCard(
                    context,
                    riskResult,
                  ),
                  const SizedBox(height: 12),
                  RiskExposureCard(
                    zoneId: HazardRiskId.zoneIdOf(
                      widget.riskId,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEvidenceCard(
                    context,
                    riskResult,
                  ),
                  const SizedBox(height: 12),
                  _buildAdviceCard(
                    context,
                  ),
                  const SizedBox(height: 12),
                  _buildRefreshCard(
                    context,
                    riskResult,
                  ),
                  const SizedBox(height: 12),
                  _buildWhatIfCard(
                    context,
                    riskResult,
                  ),
                ],
              ),
            ),
          ),
          const _RiskNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RiskResult riskResult,
    String locationLabel,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12,
      ),
      child: Row(
        children: [
          _HeaderButton(
            asset:
                'assets/icons/risk-arrow-left.svg',
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/map');
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  riskResult.locationName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Zone à risque • $locationLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPalette.textMuted,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeaderButton(
            asset:
                'assets/icons/risk-share.svg',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final color = _riskColor(
      context,
      riskResult.riskLevel,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  riskResult.riskScore
                      .toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.w700,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _RiskLevelChip(
                  level:
                      riskResult.riskLevel,
                  color: color,
                ),
                const SizedBox(height: 8),
                Text(
                  riskResult.hazardType,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppPalette.textDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mis à jour • '
                  '${_formatDateTime(
                    riskResult.updatedAt,
                  )}',
                  style: const TextStyle(
                    fontSize: 13,
                    color:
                        AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
        boxShadow: const [
          RiskDetailsScreen._cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            asset:
                'assets/icons/risk-cloud-wind.svg',
            title:
                'Pourquoi ce niveau ?',
          ),
          const SizedBox(height: 12),
          if (riskResult
              .evidence
              .qualitativeIndicators
              .isNotEmpty)
            ...riskResult
                .evidence
                .qualitativeIndicators
                .map(
                  (indicator) => Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Text(
                      indicator,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color:
                            AppPalette.textMuted,
                      ),
                    ),
                  ),
                )
          else
            Text(
              'The current risk level is based on the measured '
              'environmental data and the factors below.',
              style:
                  const TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    AppPalette.textMuted,
              ),
            ),
          const SizedBox(height: 14),
          if (_isAnalyzing)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI interpretation is being prepared...',
                  ),
                ),
              ],
            )
          else if (_analysisError != null)
            Text(
              'AI interpretation unavailable: '
              '$_analysisError',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.error,
              ),
            )
          else if (_analysis != null)
            _buildAiInterpretation(
              context,
              _analysis!,
            ),
        ],
      ),
    );
  }

  Widget _buildAiInterpretation(
    BuildContext context,
    RiskAnalysis analysis,
  ) {
    final theme =
        Theme.of(context);

    if (analysis.recommendations.isEmpty) {
      return const Text(
        'AI analysis completed for this risk result.',
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'AI interpretation',
          style:
              theme.textTheme.titleSmall?.copyWith(
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
                  Icons.auto_awesome,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text(recommendation),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactorsCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme =
        Theme.of(context);

    final factors =
        riskResult.factors;

    final entries =
        factors.entries;

    final rows = <Widget>[];

    if (entries.isEmpty) {
      rows.addAll([
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
              ? _buildUnavailableFactorRow(
                  context,
                  entry,
                )
              : _buildFactorRow(
                  context,
                  entry.label,
                  score,
                ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
        boxShadow: const [
          RiskDetailsScreen._cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            asset:
                'assets/icons/risk-cloud-wind.svg',
            title: 'Risk Factors',
          ),
          const SizedBox(height: 10),
          Text(
            'Normalized values of the factors actually available '
            'for this hazard assessment.',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0;
              index < rows.length;
              index++) ...[
            if (index > 0)
              const SizedBox(height: 12),
            rows[index],
          ],
        ],
      ),
    );
  }

  Widget _buildFactorRow(
    BuildContext context,
    String title,
    double value,
  ) {
    final clamped =
        value.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppPalette.textDark,
                ),
              ),
            ),
            Text(
              '${clamped.toStringAsFixed(0)}/100',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        LinearProgressIndicator(
          value:
              clamped / 100,
        ),
      ],
    );
  }

  Widget _buildUnavailableFactorRow(
    BuildContext context,
    dynamic entry,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
              ),
            ),
            const Text(
              'Unavailable',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          entry.unavailableReason ??
              'No measurement was available; this factor is excluded from the score.',
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }

  Widget _buildEvidenceCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme =
        Theme.of(context);

    final evidence =
        riskResult.evidence;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
        boxShadow: const [
          RiskDetailsScreen._cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            asset:
                'assets/icons/risk-cloud-rain.svg',
            title: 'Evidence',
          ),
          const SizedBox(height: 12),
          Text(
            '${evidence.observationCount} observations reçues • '
            '${evidence.confirmedObservationCount} confirmées',
            style:
                theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Collected '
            '${_formatDateTime(
              evidence.collectedAt,
            )}',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (evidence
              .measurements
              .isNotEmpty) ...[
            const SizedBox(height: 16),
            ...evidence.measurements.map(
              (measurement) =>
                  _buildMeasurement(
                context,
                measurement,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurement(
    BuildContext context,
    RiskMeasurement measurement,
  ) {
    final theme =
        Theme.of(context);

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
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
          const SizedBox(height: 5),
          Text(
            '${measurement.value.toStringAsFixed(2)} '
            '${measurement.unit}',
          ),
          if (measurement.referenceValue !=
              null) ...[
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
          if (measurement.referenceLabel !=
              null) ...[
            const SizedBox(height: 3),
            Text(
              measurement.referenceLabel!,
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (measurement.source != null) ...[
            const SizedBox(height: 3),
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
            const SizedBox(height: 3),
            Text(
              'Observed '
              '${_formatDateTime(
                measurement.observedAt!,
              )}',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdviceCard(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    if (_analysis == null &&
        !_isAnalyzing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
        boxShadow: const [
          RiskDetailsScreen._cardShadow,
        ],
      ),
      child: Column(
        children: [
          const _SectionTitle(
            asset:
                'assets/icons/risk-shield.svg',
            title:
                'Gestes recommandés',
          ),
          const SizedBox(height: 12),
          if (_isAnalyzing)
            const Text(
              'Preparing recommendations...',
            )
          else if (_analysisError !=
              null)
            Text(
              'Recommendations unavailable.',
              style:
                  theme.textTheme.bodySmall,
            )
          else if (_analysis
              ?.recommendations
              .isEmpty ??
              true)
            const Text(
              'No recommendations were returned by the AI analysis.',
            )
          else
            ..._analysis!
                .recommendations
                .map(
                  (recommendation) =>
                      Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment:
                              Alignment.center,
                          decoration:
                              BoxDecoration(
                            color: AppPalette
                                .infoBoxBg,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              8,
                            ),
                          ),
                          child:
                              SvgPicture.asset(
                            'assets/icons/risk-shield.svg',
                            width: 17,
                            height: 17,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            recommendation,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppPalette
                                  .textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildRefreshCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme =
        Theme.of(context);

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Text(
            'Actualisation',
            style:
                theme.textTheme.titleMedium?.copyWith(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Assessment automatically refreshes after '
            '${RiskResultFreshness.maxAge.inHours} hours '
            'or when recalculation is requested.',
            style:
                theme.textTheme.bodySmall,
          ),
          if (_updateError !=
              null) ...[
            const SizedBox(height: 8),
            Text(
              'Update failed: '
              '$_updateError',
              style:
                  theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isUpdatingRisk
                  ? null
                  : () =>
                      _refreshLiveRisk(
                    riskResult,
                  ),
              style:
                  ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    AppPalette.primary,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  _isUpdatingRisk
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
                          size: 19,
                        ),
                  const SizedBox(width: 8),
                  Text(
                    _isUpdatingRisk
                        ? 'Recalculating...'
                        : 'Recalculer le risque',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIfCard(
    BuildContext context,
    RiskResult riskResult,
  ) {
    final theme =
        Theme.of(context);

    final model =
        _simulationService.modelFrom(
      riskResult,
    );

    final variables = model?.variables ??
        const <RiskSimulationVariable>[];

    final values =
        <String, double>{
      for (final variable in variables)
        variable.name:
            _simulatedValues[
                  variable.name,
                ] ??
                variable.currentValue,
    };

    final changed = model == null
        ? false
        : model.adjustable.any(
            (variable) =>
                (values[
                          variable.name,
                        ]! -
                        variable.currentValue)
                    .abs() >
                0.0001,
          );

    final outcome = model != null &&
            model.isSimulatable
        ? _simulationService.simulate(
            model: model,
            values: values,
          )
        : null;

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppPalette.inputBorder,
        ),
        boxShadow: const [
          RiskDetailsScreen._cardShadow,
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            asset:
                'assets/icons/risk-cloud-rain.svg',
            title: 'What-If',
          ),
          const SizedBox(height: 8),
          Text(
            'Simulation uniquement. Ce résultat ne constitue pas une '
            'prévision et ne modifie pas le résultat réel.',
            style:
                theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (model == null)
            const Text(
              'No simulation model is available for this risk.',
            )
          else if (!model.isSimulatable)
            Text(
              model.unavailableReason ??
                  'No adjustable input is available.',
            )
          else ...[
            ...model.adjustable.map(
              (variable) {
                final value =
                    values[variable.name]!;

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
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatValue(value)} '
                          '${variable.unit}',
                        ),
                      ],
                    ),
                    Slider(
                      value: value.clamp(
                        variable.lowerBound,
                        variable.upperBound,
                      ),
                      min:
                          variable.lowerBound,
                      max:
                          variable.upperBound,
                      divisions: 60,
                      onChanged: (next) {
                        setState(() {
                          _simulatedValues[
                              variable.name] = next;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (!changed)
              const Text(
                'Adjust a value to see the simulated result.',
              )
            else if (outcome != null)
              _buildSimulationResult(
                context,
                model,
                outcome,
              ),
            TextButton.icon(
              onPressed: changed
                  ? () => setState(
                        _simulatedValues
                            .clear,
                      )
                  : null,
              icon: const Icon(
                Icons.restart_alt,
              ),
              label: const Text(
                'Back to measured values',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimulationResult(
    BuildContext context,
    RiskSimulationModel model,
    RiskSimulationOutcome outcome,
  ) {
    final color = _riskColor(
      context,
      outcome.level,
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Simulated result',
            style: TextStyle(
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${outcome.score.toStringAsFixed(0)}/100',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                outcome.level.name
                    .toUpperCase(),
                style: TextStyle(
                  fontWeight:
                      FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Simulation only — not a forecast and not stored.',
          ),
        ],
      ),
    );
  }

  Widget _buildPreparing(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final zone =
        RiskZoneCatalog.byId(
      HazardRiskId.zoneIdOf(
        widget.riskId,
      ),
    );

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(20),
            child: Row(
              children: [
                _HeaderButton(
                  asset:
                      'assets/icons/risk-arrow-left.svg',
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/map');
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      zone == null
                          ? 'Preparing risk assessment...'
                          : 'Preparing the assessment for '
                              '${zone.name}...',
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading the stored risk result and refreshing it '
                      'when necessary.',
                      textAlign:
                          TextAlign.center,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(
    BuildContext context,
    Object error,
  ) {
    final theme =
        Theme.of(context);

    return SafeArea(
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 520,
            ),
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
                  textAlign:
                      TextAlign.center,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign:
                      TextAlign.center,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .error,
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
                      const Icon(
                    Icons.refresh,
                  ),
                  label:
                      const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _riskColor(
    BuildContext context,
    RiskLevel level,
  ) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.amber.shade800;
      case RiskLevel.high:
        return Colors.orange;
      case RiskLevel.critical:
        return Theme.of(context)
            .colorScheme
            .error;
    }
  }

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final local =
        dateTime.toLocal();

    String twoDigits(int value) =>
        value.toString().padLeft(
          2,
          '0',
        );

    return '${local.year}-'
        '${twoDigits(local.month)}-'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  String _formatValue(
    double value,
  ) {
    if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    }

    if (value.abs() >= 10) {
      return value.toStringAsFixed(1);
    }

    return value.toStringAsFixed(2);
  }
}

class _HeaderButton extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.asset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          alignment:
              Alignment.center,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color:
                  AppPalette.inputBorder,
            ),
          ),
          child: SvgPicture.asset(
            asset,
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

class _RiskLevelChip extends StatelessWidget {
  final RiskLevel level;
  final Color color;

  const _RiskLevelChip({
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius:
            BorderRadius.circular(999),
        border: Border.all(
          color: color,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape:
                  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            level.name.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String asset;
  final String title;

  const _SectionTitle({
    required this.asset,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          asset,
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.w600,
            color:
                AppPalette.textDark,
          ),
        ),
      ],
    );
  }
}

class _RiskNavigation extends StatelessWidget {
  const _RiskNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color:
                AppPalette.inputBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(
            label: 'Carte',
            asset:
                'assets/icons/map-nav-map.svg',
            selected: true,
            onTap: () =>
                context.go('/map'),
          ),
          _NavItem(
            label: 'Signaler',
            asset: 'assets/icons/map-nav-plus.svg',
            onTap: () => context.push('/report'),
          ),
          _NavItem(
            label: 'Alertes',
            asset: 'assets/icons/map-nav-bell.svg',
            onTap: () => context.go('/alerts'),
          ),
          _NavItem(
            label: 'Profil',
            asset:
                'assets/icons/map-nav-user.svg',
            onTap: () =>
                context.push('/profile'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
    required this.label,
    required this.asset,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 28,
              alignment:
                  Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppPalette.infoBoxBg
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(
                  999,
                ),
              ),
              child:
                  SvgPicture.asset(
                asset,
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: selected
                    ? AppPalette.primary
                    : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}