import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      ),
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
                    _SectionCard(
                      title: 'Observations citoyennes',
                      child: observations.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => _ObservationError(error: error),
                        data: (items) {
                          if (items.isEmpty) {
                            return Text(
                              'Aucune observation citoyenne disponible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            );
                          }

                          final sorted = List<Observation>.of(items)
                            ..sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < sorted.length; i++) ...[
                                if (i > 0) const Divider(height: 24),
                                _ObservationTile(observation: sorted[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Mes signalements',
                      child: mine.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Text(
                          'Vos signalements ne sont pas disponibles pour le '
                          'moment.\n$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        data: (items) {
                           final own = items
                               .where(
                                 (item) =>
                                     hasContext
                                         ? (item.zoneId == zoneId &&
                                             item.hazardType == hazardLabel)
                                         : true,
                               )
                              .toList()
                            ..sort(
                              (a, b) => b.createdAt.compareTo(a.createdAt),
                            );

                        if (own.isEmpty) {
                          return Text(
                            'Vous n’avez encore aucun signalement.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < own.length; i++) ...[
                              if (i > 0) const Divider(height: 24),
                              _MyObservationCard(observation: own[i]),
                            ],
                          ],
                        );
                        },
                      ),
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

  Future<void> _createObservation(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({ObservationType type, String text})>(
      context: context,
      builder: (context) => const _NewObservationDialog(),
    );

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
}

class _NewObservationDialog extends StatefulWidget {
  const _NewObservationDialog();

  @override
  State<_NewObservationDialog> createState() => _NewObservationDialogState();
}

class _NewObservationDialogState extends State<_NewObservationDialog> {
  late final TextEditingController _controller;
  var _type = ObservationType.other;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              initialValue: _type,
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
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
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
            type: _type,
            text: _controller.text.trim(),
          )),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
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
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.visibility_outlined,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
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
            ],
          ),
        ),
      ],
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

    return Column(
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
    );
  }

  Widget _statusChip(BuildContext context, ObservationStatus status) {
    final theme = Theme.of(context);

    final (label, color, icon) = switch (status) {
      ObservationStatus.pending => (
        'En attente de validation',
        theme.colorScheme.tertiary,
        Icons.hourglass_top,
      ),
      ObservationStatus.confirmed => (
        '✓ Vérifié',
        theme.colorScheme.primary,
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
