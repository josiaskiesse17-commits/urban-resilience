import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../observations/domain/observation.dart';
import '../../../observations/presentation/providers/observation_providers.dart';
import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/hazard_type.dart';

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
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: observations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final observation = observations[index];

                      return _PendingObservationCard(
                        observation: observation,
                        onOpen: () => _openDetails(context, observation),
                        onApprove: () => _approve(context, ref, observation),
                        onReject: () => _reject(context, ref, observation),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }

  static String _typeLabel(ObservationType type) {
    return switch (type) {
      ObservationType.flooding => 'Inondation',
      ObservationType.blockedRoad => 'Route bloquée',
      ObservationType.landslide => 'Glissement de terrain',
      ObservationType.other => 'Autre',
    };
  }

  static String _zoneLabel(String? zoneId) {
    if (zoneId == null) {
      return 'Inconnue';
    }

    return RiskZoneCatalog.byId(zoneId)?.name ?? zoneId;
  }

  static String _hazardLabel(String? hazardType) {
    if (hazardType == null) {
      return 'Inconnu';
    }

    return HazardType.fromLabel(hazardType)?.labelFr ?? hazardType;
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  static Future<void> _openDetails(
    BuildContext context,
    Observation observation,
  ) async {
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détail de l’observation'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  observation.description ?? 'Aucune description.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Type : ${_typeLabel(observation.type)}'),
                Text('Zone : ${_zoneLabel(observation.zoneId)}'),
                Text('Risque : ${_hazardLabel(observation.hazardType)}'),
                Text('Auteur : ${observation.userId}'),
                Text('Envoyée le : ${_formatDate(observation.createdAt)}'),
                Text(
                  'Coordonnées : '
                  '${observation.latitude.toStringAsFixed(4)}, '
                  '${observation.longitude.toStringAsFixed(4)}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  static Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    Observation observation,
  ) async {
    final reviewerId = ref.read(currentUserProvider)?.id;

    if (reviewerId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’identifier le compte administrateur.'),
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(observationsRepositoryProvider)
          .approve(id: observation.id, reviewerId: reviewerId);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Observation approuvée.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approbation impossible : $error')),
        );
      }
    }
  }

  static Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    Observation observation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l’observation ?'),
        content: const Text(
          'Une observation rejetée sera supprimée définitivement '
          'et ne sera plus visible dans les signalements.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter et supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(observationsRepositoryProvider).delete(id: observation.id);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Observation supprimée.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible : $error')),
        );
      }
    }
  }
}

class _PendingObservationCard extends StatelessWidget {
  const _PendingObservationCard({
    required this.observation,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
  });

  final Observation observation;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hazardLabel =
        HazardType.fromLabel(observation.hazardType ?? '')?.labelFr ??
        observation.hazardType ??
        'Inconnu';

    final zoneLabel =
        RiskZoneCatalog.byId(observation.zoneId ?? '')?.name ??
        observation.zoneId ??
        'Inconnue';

    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                observation.description ?? 'Observation',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Zone : $zoneLabel'),
              Text('Risque : $hazardLabel'),
              Text('Auteur : ${observation.userId}'),
              Text(
                'Envoyée le : '
                '${AdminObservationsScreen._formatDate(observation.createdAt)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Ouvrir le détail',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Inspecter'),
                  ),
                  OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Rejeter et supprimer'),
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
      ),
    );
  }
}
