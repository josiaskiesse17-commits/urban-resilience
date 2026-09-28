import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdminRiskScreen extends StatefulWidget {
  const AdminRiskScreen({super.key});

  @override
  State<AdminRiskScreen> createState() => _AdminRiskScreenState();
}

class _AdminRiskScreenState extends State<AdminRiskScreen> {
  String _selectedZone = 'Masina';
  double _rainMultiplier = 1.0;

  final Map<String, int> _riskScores = {
    'Masina': 77,
    'N\'Djili': 86,
    'Limete': 48,
    'Gombe': 22,
  };

  int get _currentRisk => _riskScores[_selectedZone] ?? 0;

  int get _scenarioRisk {
    final increase = ((_rainMultiplier - 1) * 18).round();
    return math.min(100, _currentRisk + increase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Intelligence'),
      ),
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
                    _buildZoneSelector(context),
                    const SizedBox(height: 20),
                    _buildRiskSummary(context),
                    const SizedBox(height: 20),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildMeasurements(context),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildFactors(context),
                          ),
                        ],
                      )
                    else ...[
                      _buildMeasurements(context),
                      const SizedBox(height: 20),
                      _buildFactors(context),
                    ],
                    const SizedBox(height: 20),
                    _buildScenarioSimulator(context),
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
          'Risk Intelligence',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Inspect the evidence behind the current risk assessment and explore scenarios.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildZoneSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedZone,
          decoration: const InputDecoration(
            labelText: 'Risk zone',
            border: OutlineInputBorder(),
          ),
          items: _riskScores.keys
              .map(
                (zone) => DropdownMenuItem(
                  value: zone,
                  child: Text(zone),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedZone = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRiskSummary(BuildContext context) {
    final riskColor = _riskColor(_currentRisk);

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
                  _selectedZone,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                const Text('Flood risk'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: riskColor.withAlpha(30),
                  child: Text(
                    '$_currentRisk',
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
                      _riskLabel(_currentRisk),
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text('Current assessment'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurements(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Key Measurements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            const _MeasurementTile(
              title: 'Rainfall intensity',
              value: '6.4 mm/h',
              reference: '1.2 mm/h local baseline',
              comparison: '5.3× baseline',
            ),
            const _MeasurementTile(
              title: '6-hour accumulation',
              value: '36 mm',
              reference: '12 mm historical reference',
              comparison: '3× reference',
            ),
            const _MeasurementTile(
              title: 'River level',
              value: '5.1 m',
              reference: '4.6 m alert reference',
              comparison: '+0.5 m',
            ),
            const _MeasurementTile(
              title: 'Confirmed observations',
              value: '5',
              reference: '8 reports received',
              comparison: '62% confirmed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactors(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Risk Factors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 18),
            const _FactorBar(
              title: 'Rainfall',
              value: 82,
            ),
            const _FactorBar(
              title: 'Vulnerability',
              value: 76,
            ),
            const _FactorBar(
              title: 'Historical exposure',
              value: 68,
            ),
            const _FactorBar(
              title: 'Current observations',
              value: 74,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioSimulator(BuildContext context) {
    final scenarioColor = _riskColor(_scenarioRisk);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What-If Scenario',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Demo simulation until the real Risk Intelligence engine is connected.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text(
              'Rainfall multiplier: ${_rainMultiplier.toStringAsFixed(1)}×',
            ),
            Slider(
              value: _rainMultiplier,
              min: 1.0,
              max: 2.0,
              divisions: 10,
              label: '${_rainMultiplier.toStringAsFixed(1)}×',
              onChanged: (value) {
                setState(() {
                  _rainMultiplier = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _ScenarioValue(
                  label: 'Current risk',
                  value: '$_currentRisk',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                _ScenarioValue(
                  label: 'Scenario risk',
                  value: '$_scenarioRisk',
                  color: scenarioColor,
                ),
                _ScenarioValue(
                  label: 'Change',
                  value: '+${_scenarioRisk - _currentRisk}',
                  color: scenarioColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _riskColor(int score) {
    if (score >= 75) {
      return Colors.red;
    }

    if (score >= 50) {
      return Colors.orange;
    }

    if (score >= 25) {
      return Colors.amber.shade800;
    }

    return Colors.green;
  }

  String _riskLabel(int score) {
    if (score >= 75) {
      return 'CRITICAL';
    }

    if (score >= 50) {
      return 'HIGH';
    }

    if (score >= 25) {
      return 'MODERATE';
    }

    return 'LOW';
  }
}

class _MeasurementTile extends StatelessWidget {
  final String title;
  final String value;
  final String reference;
  final String comparison;

  const _MeasurementTile({
    required this.title,
    required this.value,
    required this.reference,
    required this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('$value • $reference'),
        trailing: Text(
          comparison,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  final String title;
  final int value;

  const _FactorBar({
    required this.title,
    required this.value,
  });

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
              Text('$value/100'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value / 100,
          ),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}