import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/observation.dart';
import 'providers/observations_providers.dart';

class ObservationDetailScreen extends ConsumerWidget {
  final String observationId;

  const ObservationDetailScreen({
    super.key,
    required this.observationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observations =
        ref.watch(verifiedObservationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: const Text(
          'Détail du signalement',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: observations.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text(
            'Erreur : $error',
          ),
        ),
        data: (items) {
          Observation? observation;

          for (final item in items) {
            if (item.id == observationId) {
              observation = item;
              break;
            }
          }

          if (observation == null) {
            return const Center(
              child: Text(
                'Signalement introuvable.',
              ),
            );
          }

          return _ObservationDetail(
            observation: observation,
          );
        },
      ),
    );
  }
}

class _ObservationDetail extends StatelessWidget {
  final Observation observation;

  const _ObservationDetail({
    required this.observation,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = observation.mediaUrl != null &&
        observation.mediaUrl!.isNotEmpty &&
        observation.mediaType == ObservationMediaType.image;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                observation.mediaUrl!,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
              ),
            ),

          if (hasImage) const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFD3E1E3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        observation.typeLabel,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF123C43),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF197A83),
                      size: 30,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17353B),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  observation.description ??
                      'Aucune description disponible.',
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: Color(0xFF60777B),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17353B),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF197A83),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${observation.latitude}, '
                        '${observation.longitude}',
                        style: const TextStyle(
                          color: Color(0xFF60777B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEFF1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF197A83),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ce signalement a été vérifié avant sa publication.',
                          style: TextStyle(
                            color: Color(0xFF17353B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}