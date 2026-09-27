import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/risk_analysis.dart';
import '../domain/risk_evidence.dart';
import '../domain/risk_factors.dart';
import '../domain/risk_measurement.dart';
import '../domain/risk_result.dart';
import '../domain/risk_zone.dart';
import 'providers/risk_ai_providers.dart';

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
  late final RiskResult _riskResult;

  RiskAnalysis? _analysis;
  Object? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _riskResult = _createTestRiskResult();
    _analyzeRisk();
  }

  RiskResult _createTestRiskResult() {
    final now = DateTime.now();

    return RiskResult(
      id: widget.riskId,
      locationName: 'Kinshasa — Test Zone',
      latitude: -4.325,
      longitude: 15.322,
      hazardType: 'Flooding',
      riskScore: 78,
      riskLevel: RiskLevel.high,
      factors: const RiskFactors(
        rainfall: 85,
        geographicVulnerability: 72,
        historicalExposure: 68,
        currentObservations: 81,
      ),
      evidence: RiskEvidence(
        measurements: [
          RiskMeasurement(
            name: 'rainfallIntensity',
            value: 5.2,
            unit: 'mm/h',
            measurementPeriod: '1h',
            referenceValue: 1.1,
            referenceUnit: 'mm/h',
            referenceLabel:
                'Typical rainfall intensity for this location and period',
            referenceType: RiskReferenceType.localBaseline,
            ratioToReference: 4.73,
            differenceFromReference: 4.1,
            source: 'Weather data',
            observedAt: now,
          ),
          RiskMeasurement(
            name: 'rainfallAccumulation',
            value: 32,
            unit: 'mm',
            measurementPeriod: '6h',
            referenceValue: 10,
            referenceUnit: 'mm',
            referenceLabel:
                'Typical 6-hour accumulation for this location and period',
            referenceType: RiskReferenceType.historicalAverage,
            ratioToReference: 3.2,
            differenceFromReference: 22,
            source: 'Weather data',
            observedAt: now,
          ),
          RiskMeasurement(
            name: 'geographicVulnerability',
            value: 72,
            unit: 'score/100',
            referenceValue: 50,
            referenceUnit: 'score/100',
            referenceLabel: 'Baseline vulnerability threshold',
            referenceType: RiskReferenceType.threshold,
            ratioToReference: 1.44,
            differenceFromReference: 22,
            source: 'Risk model',
            observedAt: now,
          ),
        ],
        qualitativeIndicators: const [
          'Recent reports indicate water accumulation nearby.',
          'The area has previous exposure to flooding.',
        ],
        observationCount: 6,
        confirmedObservationCount: 4,
        collectedAt: now,
      ),
      updatedAt: now,
    );
  }

  Future<void> _analyzeRisk() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _analysis = null;
    });

    try {
      final analysis = await ref
          .read(riskAnalystProvider)
          .analyze(_riskResult);

      if (!mounted) {
        return;
      }

      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Color _riskColor(BuildContext context) {
    switch (_riskResult.riskLevel) {
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
    final theme = Theme.of(context);
    final riskColor = _riskColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _riskResult.locationName,
                          style:
                              theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _riskResult.hazardType,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        Row(
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
                                _riskResult.riskLevel.name
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_riskResult.riskScore.toStringAsFixed(0)}/100',
                              style:
                                  theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
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
                          'The AI interprets the available risk measurements, '
                          'context, observations, and calculated risk level.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_error != null)
                          _buildError(context)
                        else if (_analysis != null)
                          _buildAnalysis(
                            context,
                            _analysis!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(analysis.summary),
        const SizedBox(height: 20),
        Text(
          'Why?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(analysis.explanation),
        const SizedBox(height: 20),
        Text(
          'Main factors',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...analysis.mainFactors.map(
          (factor) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
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
        const SizedBox(height: 12),
        Text(
          'Recommendations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...analysis.recommendations.map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(recommendation),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'The AI analysis could not be generated.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          _error.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isLoading ? null : _analyzeRisk,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}