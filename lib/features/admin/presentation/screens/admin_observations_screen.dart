import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../observations/domain/observation.dart';
import '../../../observations/presentation/providers/observation_providers.dart';

class AdminObservationsScreen extends ConsumerWidget {
  const AdminObservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingObservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Observations à valider')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (observations) => observations.isEmpty
            ? const Center(child: Text('Aucune observation en attente.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: observations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _PendingObservationCard(
                  observation: observations[index],
                  onApprove: () => _setStatus(
                    context,
                    ref,
                    observations[index],
                    ObservationStatus.confirmed,
                  ),
                  onReject: () => _setStatus(
                    context,
                    ref,
                    observations[index],
                    ObservationStatus.rejected,
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    Observation observation,
    ObservationStatus status,
  ) async {
    try {
      await ref
          .read(observationsRepositoryProvider)
          .setStatus(observation.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == ObservationStatus.confirmed
                  ? 'Observation approuvée.'
                  : 'Observation rejetée.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
      }
    }
  }
}

class _PendingObservationCard extends StatelessWidget {
  const _PendingObservationCard({
    required this.observation,
    required this.onApprove,
    required this.onReject,
  });

  final Observation observation;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              observation.description ?? 'Observation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Zone : ${observation.zoneId ?? 'Inconnue'}'),
            Text('Risque : ${observation.hazardType ?? 'Inconnu'}'),
            Text('Auteur : ${observation.userId}'),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Rejeter'),
                ),
                FilledButton(
                  onPressed: onApprove,
                  child: const Text('Approuver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
