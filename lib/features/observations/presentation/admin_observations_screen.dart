import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/observation.dart';
import 'providers/observations_providers.dart';

class AdminObservationsScreen extends ConsumerWidget {
  const AdminObservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return isAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Administration')), 
        body: Center(child: Text('Erreur : $error')),
      ),
      data: (allowed) {
        if (!allowed) {
          return const Scaffold(
            body: Center(child: Text('Accès administrateur requis.')),
          );
        }

        final pending = ref.watch(pendingObservationsProvider);
        return Scaffold(
          appBar: AppBar(title: const Text('Validation des observations')),
          body: pending.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erreur : $error')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text('Aucune observation en attente.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) => _PendingCard(
                  observation: items[index],
                  onValidated: () => ref.invalidate(pendingObservationsProvider),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  final Observation observation;
  final VoidCallback onValidated;

  const _PendingCard({
    required this.observation,
    required this.onValidated,
  });

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _loading = false;

  Future<void> _validate() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(observationsRepositoryProvider)
          .verifyObservation(widget.observation.id);
      widget.onValidated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observation validée.')),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le signalement'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Motif (facultatif)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(observationsRepositoryProvider).rejectObservation(
            widget.observation.id,
            reason: reason,
          );
      widget.onValidated();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur : $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.observation;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.typeLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(item.description?.isNotEmpty == true
                ? item.description!
                : 'Aucune description.'),
            const SizedBox(height: 8),
            Text(
              'GPS : ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}',
            ),
            if (item.mediaUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText('Preuve : ${item.mediaUrl}'),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      child: const Text('Rejeter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _validate,
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
