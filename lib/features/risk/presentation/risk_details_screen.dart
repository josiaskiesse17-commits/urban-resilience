import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../observations/domain/observation.dart';
import '../domain/risk_analysis.dart';
import '../domain/risk_measurement.dart';
import '../domain/risk_result.dart';
import '../domain/risk_zone.dart';
import 'providers/risk_ai_providers.dart';
import 'providers/risk_live_providers.dart';

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
  static final DateTime _baselineStart =
      DateTime.utc(2018, 1, 1);

  static final DateTime _baselineEnd =
      DateTime.utc(2022, 7, 31);

  RiskAnalysis? _analysis;
  Object? _analysisError;

  bool _isAnalyzing = false;
  bool _isRefreshingRisk = false;

  String? _analyzedRiskId;

  Future<void> _analyzeRisk(RiskResult riskResult) async {
    if (_isAnalyzing ||
        _analyzedRiskId == riskResult.id) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
      _analysis = null;
      _analyzedRiskId = riskResult.id;
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
        _analyzedRiskId = null;
      });
    }
  }

  Future<void> _refreshLiveRisk(
    RiskResult currentResult,
  ) async {
    if (_isRefreshingRisk) {
      return;
    }

    setState(() {
      _isRefreshingRisk = true;
      _analysis = null;
      _analysisError = null;
      _analyzedRiskId = null;
    });

    try {
      final service =
          ref.read(liveFloodRiskServiceProvider);

      await service.calculateLiveRiskAndSave(
        id: currentResult.id,
        zoneId: currentResult.id,
        locationName: currentResult.locationName,
        latitude: currentResult.latitude,
        longitude: currentResult.longitude,
        startDate: _baselineStart,
        endDate: _baselineEnd,
        observations: const <Observation>[],
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(
        riskResultProvider(widget.riskId),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live risk updated successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update live risk: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingRisk = false;
        });
      }
    }
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
        ref.watch(riskResultProvider(widget.riskId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
      ),
      body: riskAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) =>
            _buildLoadError(context, error),
        data: (riskResult) {
          if (riskResult == null) {
            return _buildNotFound(context);
          }

          if (_analyzedRiskId != riskResult.id &&
              !_isAnalyzing &&
              !_isRefreshingRisk) {
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

  Widget _buildRiskContent(
    BuildContext context,
    RiskResult riskResult,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          riskResultProvider(widget.riskId),
        );
      },
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
                _buildRiskSummary(
                  context,
                  riskResult,
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
              ],
            ),
          ),
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
              'Fetch current environmental data, '
              'recalculate the flood risk, and save the '
              'new result.',
              style:
                  theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isRefreshingRisk
                  ? null
                  : () => _refreshLiveRisk(
                        riskResult,
                      ),
              icon: _isRefreshingRisk
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
                _isRefreshingRisk
                    ? 'Updating risk...'
                    : 'Refresh live risk',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Historical reference: '
              '${_formatDate(_baselineStart)} – '
              '${_formatDate(_baselineEnd)}',
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
            const SizedBox(height: 16),
            _buildFactorRow(
              context,
              'Rainfall',
              riskResult.factors.rainfall,
            ),
            const SizedBox(height: 12),
            _buildFactorRow(
              context,
              'Geographic vulnerability',
              riskResult
                  .factors
                  .geographicVulnerability,
            ),
            const SizedBox(height: 12),
            _buildFactorRow(
              context,
              'Historical exposure',
              riskResult
                  .factors
                  .historicalExposure,
            ),
            const SizedBox(height: 12),
            _buildFactorRow(
              context,
              'Current observations',
              riskResult
                  .factors
                  .currentObservations,
            ),
          ],
        ),
      ),
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
              measurement.name,
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
              'The AI interprets the calculated risk, '
              'measurements, evidence, and observations.',
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
                    _analyzeRisk(
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
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () =>
              _retryAnalysis(
            riskResult,
          ),
          icon:
              const Icon(Icons.refresh),
          label:
              const Text('Try again'),
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
                    widget.riskId,
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

  Widget _buildNotFound(
    BuildContext context,
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
              Icons.search_off,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Risk result not found.',
              style:
                  theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No saved risk result exists for '
              '"${widget.riskId}".',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _retryAnalysis(
    RiskResult riskResult,
  ) {
    setState(() {
      _analyzedRiskId = null;
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