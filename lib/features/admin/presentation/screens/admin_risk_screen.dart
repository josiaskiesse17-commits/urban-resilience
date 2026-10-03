import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/hazard_risk_id.dart';
import '../../../risk/domain/hazard_type.dart';
import '../../../risk/domain/risk_measurement.dart';
import '../../../risk/domain/risk_result.dart';
import '../../../risk/domain/risk_result_freshness.dart';
import '../../../risk/domain/risk_scenario.dart';
import '../../../risk/domain/risk_scenario_result.dart';
import '../../../risk/domain/risk_zone.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';
import '../../../risk/presentation/widgets/risk_exposure_card.dart';

class AdminRiskScreen extends ConsumerStatefulWidget {
  const AdminRiskScreen({super.key});

  @override
  ConsumerState<AdminRiskScreen> createState() => _AdminRiskScreenState();
}

class _AdminRiskScreenState extends ConsumerState<AdminRiskScreen> {
  static const double _maxRainfallMultiplier = 2.0;

  String? _selectedZoneId;

  /// Hazard currently inspected.
  HazardType _selectedHazard = HazardType.flooding;

  double _rainfallMultiplier = 1.0;

  bool _isRefreshing = false;
  bool _isSimulating = false;

  Object? _refreshError;
  Object? _simulationError;
  RiskScenarioResult? _simulation;

  /// Zone/hazard that already went through the automatic load-or-generate
  /// step, so rebuilding does not start another generation.
  String? _updateAttemptedForZoneId;

  String _riskIdFor(RiskZoneTarget zone) {
    return HazardRiskId.forZone(zoneId: zone.id, hazard: _selectedHazard);
  }

  String _attemptKey(RiskZoneTarget zone) {
    return '${zone.id}|${_selectedHazard.id}';
  }

  RiskZoneTarget _selectedZone(List<RiskZoneTarget> zones) {
    final selectedId = _selectedZoneId;

    for (final zone in zones) {
      if (zone.id == selectedId) {
        return zone;
      }
    }

    return zones.first;
  }

  Future<void> _ensureFreshRisk(RiskZoneTarget zone) async {
    if (_isRefreshing || _updateAttemptedForZoneId == _attemptKey(zone)) {
      return;
    }

    setState(() {
      _updateAttemptedForZoneId = _attemptKey(zone);
    });

    await _refreshLiveRisk(zone, announce: false);
  }

  Future<void> _refreshLiveRisk(
    RiskZoneTarget zone, {
    bool announce = true,
  }) async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _refreshError = null;
      _updateAttemptedForZoneId = _attemptKey(zone);
    });

    try {
      await ref.read(zoneHazardRiskGeneratorProvider)(zone, _selectedHazard);

      if (!mounted) {
        return;
      }

      ref.invalidate(riskResultProvider(_riskIdFor(zone)));

      setState(() {
        _isRefreshing = false;
        _refreshError = null;
        _simulation = null;
        _simulationError = null;
      });

      if (!announce) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Risque actualisé pour ${zone.name}.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRefreshing = false;
        _refreshError = error;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actualisation impossible : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(riskZoneCatalogProvider);

    if (zones.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Intelligence des risques')),
        body: const Center(child: Text('Aucune zone à risque n’est configurée.')),
      );
    }

    final zone = _selectedZone(zones);
    final riskAsync = ref.watch(riskResultProvider(_riskIdFor(zone)));

    if (!riskAsync.isLoading &&
        RiskResultFreshness.needsUpdate(riskAsync.value) &&
        !_isRefreshing &&
        _updateAttemptedForZoneId != _attemptKey(zone)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensureFreshRisk(zone);
        }
      });
    }

    final riskResult = riskAsync.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Intelligence des risques')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    _buildZoneSelector(context, zones, zone),
                    const SizedBox(height: 20),
                    _buildHazardSelector(context),
                    const SizedBox(height: 20),
                    _buildRiskSummary(context, zone, riskAsync),
                    const SizedBox(height: 20),
                    RiskExposureCard(zoneId: zone.id),
                    if (riskResult == null) ...[
                      const SizedBox(height: 20),
                      _buildPendingAssessment(context, zone, riskAsync),
                    ] else ...[
                      const SizedBox(height: 20),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMeasurements(context, riskResult),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: _buildFactors(context, riskResult)),
                          ],
                        )
                      else ...[
                        _buildMeasurements(context, riskResult),
                        const SizedBox(height: 20),
                        _buildFactors(context, riskResult),
                      ],
                      const SizedBox(height: 20),
                      _buildEvidence(context, riskResult),
                      if (_selectedHazard == HazardType.flooding) ...[
                        const SizedBox(height: 20),
                        _buildScenarioSimulator(context, zone, riskResult),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intelligence des risques',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Examinez les preuves derrière l’évaluation actuelle du risque et '
          'explorez des scénarios.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildZoneSelector(
    BuildContext context,
    List<RiskZoneTarget> zones,
    RiskZoneTarget selected,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DropdownButtonFormField<String>(
          initialValue: selected.id,
          decoration: const InputDecoration(
            labelText: 'Zone à risque',
            border: OutlineInputBorder(),
          ),
          items: zones
              .map(
                (zone) =>
                    DropdownMenuItem(value: zone.id, child: Text(zone.name)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedZoneId = value;
              _simulation = null;
              _simulationError = null;
              _refreshError = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildHazardSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risque',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: HazardType.values
                  .map(
                    (hazard) => ChoiceChip(
                      label: Text(hazard.labelFr),
                      selected: hazard == _selectedHazard,
                      onSelected: (selected) {
                        if (!selected || hazard == _selectedHazard) {
                          return;
                        }

                        setState(() {
                          _selectedHazard = hazard;
                          _simulation = null;
                          _simulationError = null;
                          _refreshError = null;
                          _updateAttemptedForZoneId = null;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSummary(
    BuildContext context,
    RiskZoneTarget zone,
    AsyncValue<RiskResult?> riskAsync,
  ) {
    final theme = Theme.of(context);
    final riskResult = riskAsync.value;
    final riskLevel = riskResult?.riskLevel;

    final riskColor = riskLevel == null
        ? theme.colorScheme.onSurfaceVariant
        : _riskColor(context, riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 20,
          spacing: 30,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(riskResult?.hazardType == null
                    ? _selectedHazard.labelFr
                    : (_hazardLabelOf(riskResult!.hazardType))),
                const SizedBox(height: 6),
                Text(
                  riskResult == null
                      ? 'Aucune évaluation enregistrée pour cette zone.'
                      : 'Mis à jour le ${_formatDateTime(riskResult.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: riskColor.withAlpha(30),
                      child: Text(
                        riskResult == null
                            ? '—'
                            : riskResult.riskScore.toStringAsFixed(0),
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riskLevel == null
                              ? 'AUCUNE DONNÉE'
                              : _riskLevelLabel(riskLevel),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('Évaluation actuelle'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _isRefreshing
                      ? null
                      : () => _refreshLiveRisk(zone),
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isRefreshing
                        ? 'Recalcul en cours...'
                        : 'Recalculer le risque actuel',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAssessment(
    BuildContext context,
    RiskZoneTarget zone,
    AsyncValue<RiskResult?> riskAsync,
  ) {
    final theme = Theme.of(context);
    final refreshError = _refreshError;
    final error = refreshError ?? riskAsync.error;

    if (error == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Préparation de l’évaluation pour ${zone.name}...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Référence historique, données environnementales actuelles et profil d’exposition enregistré. Aucune action n’est requise.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun résultat de risque ne peut être chargé pour cette zone',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isRefreshing ? null : () => _refreshLiveRisk(zone),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements(BuildContext context, RiskResult riskResult) {
    final measurements = riskResult.evidence.measurements;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mesures clés',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (measurements.isEmpty)
              const Text('Aucune mesure enregistrée.')
            else
              for (final measurement in measurements
                  .where((measurement) =>
                      measurement.name != 'citizenObservationRisk'))
                _MeasurementTile(
                  title: _measurementTitle(measurement.name),
                  value:
                      '${measurement.value.toStringAsFixed(2)} '
                      '${measurement.unit}',
                  reference: _measurementReference(measurement),
                  comparison: _measurementComparison(measurement),
                  source: measurement.source,
                ),
          ],
        ),
      ),
    );
  }

  String _hazardLabelOf(String storedLabel) {
    return HazardType.fromLabel(storedLabel)?.labelFr ?? storedLabel;
  }

  String _measurementTitle(String name) {
    switch (name) {
      case 'rainfallIntensity':
        return 'Intensité de la pluie';

      case 'rainfallAccumulation6h':
        return 'Cumul sur 6 heures';

      case 'riverDischarge':
      case 'riverDischargeM3s':
        return 'Débit fluvial — m³/s';

      case 'geographicVulnerability':
        return 'Vulnérabilité géographique';

      case 'historicalExposure':
        return 'Exposition historique';

      case 'citizenObservationRisk':
        return 'Risque lié aux observations citoyennes';

      default:
        return RiskMeasurement.humanizeName(name);
    }
  }

  String _measurementReference(RiskMeasurement measurement) {
    final referenceValue = measurement.referenceValue;

    if (referenceValue == null) {
      return measurement.referenceLabel ?? 'Aucune référence enregistrée';
    }

    final unit = measurement.referenceUnit == null
        ? ''
        : ' ${measurement.referenceUnit}';

    final reference = '${referenceValue.toStringAsFixed(2)}$unit';

    final label = measurement.referenceLabel;

    if (label == null) {
      return 'Référence $reference';
    }

    return '$label ($reference)';
  }

  String _measurementComparison(RiskMeasurement measurement) {
    final ratio = measurement.ratioToReference;

    if (ratio != null) {
      return '×${ratio.toStringAsFixed(2)}';
    }

    final difference = measurement.differenceFromReference;

    if (difference != null) {
      final sign = difference >= 0 ? '+' : '';

      return '$sign${difference.toStringAsFixed(2)}';
    }

    return '';
  }

  Widget _buildFactors(BuildContext context, RiskResult riskResult) {
    final entries = riskResult.factors.entries;

    final factors = riskResult.factors;

    final rows = entries.isEmpty
        ? <Widget>[
            _FactorBar(
              title: factors.primaryFactorLabel,
              value: factors.rainfall,
            ),
            _FactorBar(
              title: 'Vulnérabilité géographique',
              value: factors.geographicVulnerability,
            ),
            _FactorBar(
              title: 'Exposition historique',
              value: factors.historicalExposure,
            ),
          ]
        : <Widget>[
            for (final entry in entries)
              entry.score == null
                  ? ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.label),
                      subtitle: Text(
                        entry.unavailableReason ??
                            'Aucune mesure disponible ; ce facteur est '
                                'exclu du score.',
                      ),
                      trailing: const Text(
                        'Indisponible',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : _FactorBar(
                      title: entry.label,
                      value: entry.score!,
                    ),
          ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Facteurs de risque',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const SizedBox(height: 14),
              rows[index],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvidence(BuildContext context, RiskResult riskResult) {
    final theme = Theme.of(context);
    final evidence = riskResult.evidence;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Éléments de preuve',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${evidence.observationCount} '
              'observations reçues • '
              '${evidence.confirmedObservationCount} '
              'confirmées',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Collectées le ${_formatDateTime(evidence.collectedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (evidence.qualitativeIndicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Indicateurs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...evidence.qualitativeIndicators.map(
                (indicator) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 7),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(indicator)),
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

  Widget _buildScenarioSimulator(
    BuildContext context,
    RiskZoneTarget zone,
    RiskResult riskResult,
  ) {
    final theme = Theme.of(context);
    final simulation = _simulation;
    final scenarioResult = simulation?.scenario;

    final scenarioColor = scenarioResult == null
        ? theme.colorScheme.onSurfaceVariant
        : _riskColor(context, scenarioResult.riskLevel);

    final scenarioScore = scenarioResult == null
        ? '—'
        : scenarioResult.riskScore.toStringAsFixed(0);

    final difference = simulation?.scoreDifference;

    final changeLabel = difference == null
        ? '—'
        : '${difference >= 0 ? '+' : ''}'
              '${difference.toStringAsFixed(0)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scénario hypothétique',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Récupère les données actuelles de pluie et de débit fluvial, reconstruit les données du risque et applique le multiplicateur du scénario.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text(
              'Multiplicateur de pluie : '
              '${_rainfallMultiplier.toStringAsFixed(1)}×',
            ),
            Slider(
              value: _rainfallMultiplier,
              min: 1.0,
              max: _maxRainfallMultiplier,
              divisions: 10,
              label: '${_rainfallMultiplier.toStringAsFixed(1)}×',
              onChanged: (value) {
                setState(() {
                  _rainfallMultiplier = value;
                });
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSimulating
                  ? null
                  : () => _runScenario(zone, riskResult),
              icon: _isSimulating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.science_outlined),
              label: Text(
                _isSimulating ? 'Simulation en cours...' : 'Lancer le scénario',
              ),
            ),
            if (_simulationError != null) ...[
              const SizedBox(height: 12),
              Text(
                'Impossible d’exécuter le scénario : '
                '$_simulationError',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _ScenarioValue(
                  label: 'Risque actuel',
                  value: riskResult.riskScore.toStringAsFixed(0),
                  color: theme.colorScheme.onSurface,
                ),
                _ScenarioValue(
                  label: 'Risque simulé',
                  value: scenarioScore,
                  color: scenarioColor,
                ),
                _ScenarioValue(
                  label: 'Évolution',
                  value: changeLabel,
                  color: scenarioColor,
                ),
              ],
            ),
            if (simulation != null) ...[
              const SizedBox(height: 12),
              Text(
                simulation.riskLevelChanged
                    ? 'Le scénario modifie le niveau à '
                          '${simulation.scenario.riskLevel.name.toUpperCase()}.'
                    : 'Le scénario maintient le niveau à '
                          '${simulation.scenario.riskLevel.name.toUpperCase()}.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runScenario(RiskZoneTarget zone, RiskResult current) async {
    if (_isSimulating) {
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationError = null;
      _simulation = null;
    });

    try {
      final result = await ref
          .read(liveFloodRiskServiceProvider)
          .simulateFloodScenario(
            id: zone.id,
            locationName: zone.name,
            latitude: zone.latitude,
            longitude: zone.longitude,
            startDate: RiskZoneCatalog.historicalBaselineStart,
            endDate: RiskZoneCatalog.historicalBaselineEnd,
            scenario: RiskScenario(
              name:
                  'Rainfall '
                  '×${_rainfallMultiplier.toStringAsFixed(1)}',
              rainfallMultiplier: _rainfallMultiplier,
              rainfallAccumulationMultiplier: _rainfallMultiplier,
            ),
            vulnerabilityScore: current.factors.geographicVulnerability,
            historicalExposureScore: current.factors.historicalExposure,
            observationScore: current.factors.currentObservations,
            observationCount: current.evidence.observationCount,
            confirmedObservationCount:
                current.evidence.confirmedObservationCount,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _simulation = result;
        _isSimulating = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _simulationError = error;
        _isSimulating = false;
      });
    }
  }

  Color _riskColor(BuildContext context, RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.low:
        return Colors.green;

      case RiskLevel.medium:
        return Colors.amber.shade800;

      case RiskLevel.high:
        return Colors.orange;

      case RiskLevel.critical:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _riskLevelLabel(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => 'FAIBLE',
      RiskLevel.medium => 'MOYEN',
      RiskLevel.high => 'ÉLEVÉ',
      RiskLevel.critical => 'CRITIQUE',
    };
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${local.year}-'
        '${twoDigits(local.month)}-'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }
}

class _MeasurementTile extends StatelessWidget {
  final String title;
  final String value;
  final String reference;
  final String comparison;
  final String? source;

  const _MeasurementTile({
    required this.title,
    required this.value,
    required this.reference,
    required this.comparison,
    this.source,
  });

  @override
  Widget build(BuildContext context) {
    final details = source == null
        ? '$value • $reference'
        : '$value • $reference • Source : $source';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(details),
        trailing: Text(
          comparison,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  final String title;
  final double value;

  const _FactorBar({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Text('${value.toStringAsFixed(0)}/100'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (value / 100).clamp(0.0, 1.0)),
        ],
      ),
    );
  }
}

class _ScenarioValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScenarioValue({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
