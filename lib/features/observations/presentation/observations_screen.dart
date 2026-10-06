import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../risk/data/risk_repository.dart';
import '../../risk/domain/hazard_type.dart';
import '../domain/observation.dart';
import 'providers/observation_providers.dart';

class ObservationsScreen extends ConsumerWidget {
  const ObservationsScreen({super.key, this.zoneId, this.hazardType});

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
        : const AsyncValue<List<Observation>>.data(<Observation>[]);
    final mine = ref.watch(myObservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Observations citoyennes')),
      body: !hasContext
          ? const Center(
              child: Text('Sélectionnez un risque pour voir ses observations.'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionTitle(context, 'Observations citoyennes'),
                    const SizedBox(height: 8),
                    observations.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _ObservationError(error: error),
                      data: (items) => items.isEmpty
                          ? const Text(
                              'Aucune observation citoyenne disponible.',
                              textAlign: TextAlign.center,
                            )
                          : Column(
                              children: [
                                for (final item in items) ...[
                                  _ObservationTile(observation: item),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle(context, 'Mes signalements'),
                    const SizedBox(height: 8),
                    mine.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text(
                        'Vos signalements ne sont pas disponibles pour le '
                        'moment.\n$error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      data: (items) {
                        final own = items
                            .where(
                              (item) =>
                                  item.zoneId == zoneId &&
                                  item.hazardType == hazardLabel,
                            )
                            .toList();

                        if (own.isEmpty) {
                          return Text(
                            'Vous n’avez encore rien signalé pour ce risque '
                            'dans cette zone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final item in own) ...[
                              _MyObservationCard(observation: item),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: hasContext
          ? FloatingActionButton.extended(
              onPressed: () => _createObservation(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Signaler'),
            )
          : null,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Future<void> _createObservation(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    var type = ObservationType.other;
    final result = await showDialog<({ObservationType type, String text})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Nouvelle observation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ObservationType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ObservationType.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_typeLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => type = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez ce que vous observez',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                type: type,
                text: controller.text.trim(),
              )),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (result == null || result.text.isEmpty) return;
    final zone = RiskZoneCatalog.byId(zoneId!);
    if (zone == null) return;
    final hazardLabel = HazardType.fromId(hazardType!)?.label ?? hazardType!;

    try {
      await ref
          .read(observationsRepositoryProvider)
          .create(
            zoneId: zoneId!,
            hazardType: hazardLabel,
            latitude: zone.latitude,
            longitude: zone.longitude,
            type: result.type,
            description: result.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Observation reçue. Elle est en attente de validation.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Envoi impossible : $error')));
      }
    }
  }

  static String _typeLabel(ObservationType type) {
    return switch (type) {
      ObservationType.flooding => 'Inondation',
      ObservationType.blockedRoad => 'Route bloquée',
      ObservationType.landslide => 'Glissement de terrain',
      ObservationType.heat => 'Chaleur',
      ObservationType.other => 'Autre',
    };
  }
}

class _ObservationError extends StatelessWidget {
  const _ObservationError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Les observations ne sont pas disponibles pour le moment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez la connexion et les droits Firestore.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.visibility_outlined),
        title: Text(observation.description ?? 'Observation'),
        subtitle: Text(_formatDate(observation.createdAt)),
      ),
    );
  }
}

class _MyObservationCard extends StatelessWidget {
  const _MyObservationCard({required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = observation.status;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              observation.description ?? 'Observation',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(observation.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _statusChip(context, status),
                if (status == ObservationStatus.rejected &&
                    (observation.rejectionReason?.isNotEmpty ?? false))
                  Text(
                    'Motif : ${observation.rejectionReason}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, ObservationStatus status) {
    final theme = Theme.of(context);

    final (label, color, icon) = switch (status) {
      ObservationStatus.pending => (
        'En attente de validation',
        Colors.amber.shade800,
        Icons.hourglass_top,
      ),
      ObservationStatus.confirmed => (
        '✓ Vérifié',
        Colors.green.shade700,
        Icons.check_circle_outline,
      ),
      ObservationStatus.rejected => (
        'Rejeté',
        theme.colorScheme.error,
        Icons.close,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();

  String two(int value) => value.toString().padLeft(2, '0');

  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
