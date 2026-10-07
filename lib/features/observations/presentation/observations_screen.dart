import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../risk/domain/hazard_type.dart';
import '../domain/observation.dart';
import 'providers/observation_providers.dart';

class ObservationsScreen extends ConsumerWidget {
  const ObservationsScreen({
    super.key,
    this.zoneId,
    this.hazardType,
  });

  final String? zoneId;
  final String? hazardType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasContext = zoneId != null && hazardType != null;

    final hazardLabel = hasContext
        ? HazardType.fromId(hazardType!)?.label ?? hazardType!
        : null;

    final observations = hasContext
        ? ref.watch(
            observationsForContextProvider((
              zoneId: zoneId!,
              hazardType: hazardLabel!,
            )),
          )
        : ref.watch(allConfirmedObservationsProvider);

    final mine = ref.watch(myObservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observations citoyennes'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/map');
            }
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: hasContext
          ? _ContextView(observations: observations)
          : _GlobalView(mine: mine),
    );
  }
}

class _GlobalView extends StatelessWidget {
  const _GlobalView({
    required this.mine,
  });

  final AsyncValue<List<Observation>> mine;

  @override
  Widget build(BuildContext context) {
    return mine.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Impossible de charger vos signalements.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (observations) {
        if (observations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Vous n’avez aucun signalement en attente.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Mes signalements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos signalements sont affichés ici tant qu’ils sont en attente de vérification.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...observations.map(
              (observation) => _ObservationCard(
                observation: observation,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContextView extends StatelessWidget {
  const _ContextView({
    required this.observations,
  });

  final AsyncValue<List<Observation>> observations;

  @override
  Widget build(BuildContext context) {
    return observations.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Impossible de charger les observations citoyennes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucune observation citoyenne confirmée pour cette zone.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Observations citoyennes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Observations confirmées dans cette zone.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (observation) => _ObservationCard(
                observation: observation,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.observation,
  });

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final description = observation.description?.trim();
    final typeName = observation.type.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (typeName.isNotEmpty)
              Text(
                typeName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(observation.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year à $hour:$minute';
  }
}