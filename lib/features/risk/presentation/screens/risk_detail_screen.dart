import 'package:flutter/material.dart';

import '../../../map/domain/entities/map_risk.dart';

class RiskDetailScreen extends StatelessWidget {
  final MapRisk risk;

  const RiskDetailScreen({
    super.key,
    required this.risk,
  });

  Color _getColor() {
    switch (risk.level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return Colors.red;
    }
  }

  String _levelText() {
    switch (risk.level) {
      case RiskLevel.low:
        return 'Faible';
      case RiskLevel.medium:
        return 'Modéré';
      case RiskLevel.high:
        return 'Élevé';
      case RiskLevel.critical:
        return 'Critique';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du risque'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color,
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          risk.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Niveau : ${_levelText()}',
                          style: TextStyle(
                            color: color,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Description',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 10),

            Text(
              risk.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),

            if (risk.address != null) ...[
              const SizedBox(height: 28),

              Text(
                'Localisation',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 10),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.location_on,
                ),
                title: Text(risk.address!),
                subtitle: Text(
                  '${risk.position.latitude.toStringAsFixed(5)}, '
                  '${risk.position.longitude.toStringAsFixed(5)}',
                ),
              ),
            ],

            if (risk.reportedAt != null) ...[
              const SizedBox(height: 20),

              Text(
                'Signalé le',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                risk.reportedAt.toString(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}