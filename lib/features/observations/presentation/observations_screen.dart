import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/observation.dart';
import 'providers/observations_providers.dart';

class ObservationsScreen extends ConsumerWidget {
  const ObservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verified = ref.watch(verifiedObservationsProvider);
    final mine = ref.watch(myObservationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Signalements',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF197A83),
        onPressed: () {
          context.push('/observations/report');
        },
        icon: const Icon(Icons.add),
        label: const Text('Signaler'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(verifiedObservationsProvider);
          ref.invalidate(myObservationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),
          children: [
            // -----------------------------------------------------------
            // HEADER
            // -----------------------------------------------------------
            const Text(
              'Publications citoyennes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF123C43),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Découvrez les situations signalées et vérifiées autour de vous.',
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF60777B),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------
            // PUBLICATIONS VERIFIEES
            // -----------------------------------------------------------
            const Text(
              'Signalements vérifiés',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF123C43),
              ),
            ),

            const SizedBox(height: 14),

            verified.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorCard(
                message: 'Impossible de charger les publications.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCard(
                    message:
                        'Aucun signalement vérifié pour le moment.',
                  );
                }

                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ObservationCard(
                            observation: item,
                            verified: true,
                            onTap: () {
                              context.push(
                                '/observations/detail/${item.id}',
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // -----------------------------------------------------------
            // MES SIGNALEMENTS
            // -----------------------------------------------------------
            const Text(
              'Mes signalements',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: Color(0xFF123C43),
              ),
            ),

            const SizedBox(height: 14),

            mine.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => _ErrorCard(
                message: 'Impossible de charger vos signalements.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyCard(
                    message:
                        'Vous n’avez encore envoyé aucun signalement.',
                  );
                }

                return Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ObservationCard(
                            observation: item,
                            verified: false,
                            onTap: () {
                              context.push(
                                '/observations/detail/${item.id}',
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final Observation observation;
  final bool verified;
  final VoidCallback onTap;

  const _ObservationCard({
    required this.observation,
    required this.verified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = observation.mediaUrl != null &&
        observation.mediaUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD3E1E3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasMedia &&
                observation.mediaType == ObservationMediaType.image)
              Image.network(
                observation.mediaUrl!,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return _MediaPlaceholder();
                },
              )
            else
              const _MediaPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          observation.typeLabel,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17353B),
                          ),
                        ),
                      ),
                      _StatusBadge(
                        status: observation.status,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    observation.description?.isNotEmpty == true
                        ? observation.description!
                        : 'Aucune description.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Color(0xFF60777B),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: Color(0xFF197A83),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${observation.latitude.toStringAsFixed(4)}, '
                          '${observation.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: Color(0xFF60777B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                        color: Color(0xFF197A83),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      color: const Color(0xFFDDEFF1),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 55,
          color: Color(0xFF197A83),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ObservationStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String label;

    switch (status) {
      case ObservationStatus.pending:
        label = 'En attente';
        break;
      case ObservationStatus.verified:
        label = 'Vérifié';
        break;
      case ObservationStatus.rejected:
        label = 'Rejeté';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status == ObservationStatus.verified
            ? const Color(0xFFDDEFF1)
            : const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF197A83),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD3E1E3),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF60777B),
          fontSize: 15,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }
}