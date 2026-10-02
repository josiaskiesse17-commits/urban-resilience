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

    return Scaffold(
      appBar: AppBar(title: const Text('Observations')),
      body: !hasContext
          ? const Center(
              child: Text('Sélectionnez un risque pour voir ses observations.'),
            )
          : observations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ObservationError(error: error),
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune observation disponible pour ce risque dans cette zone.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _ObservationTile(observation: items[index]),
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
        subtitle: Text(observation.createdAt.toLocal().toString()),
      ),
    );
  }
}
