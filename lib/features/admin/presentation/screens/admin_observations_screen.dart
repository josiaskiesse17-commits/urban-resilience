import 'package:flutter/material.dart';

class AdminObservationsScreen extends StatefulWidget {
  const AdminObservationsScreen({super.key});

  @override
  State<AdminObservationsScreen> createState() =>
      _AdminObservationsScreenState();
}

class _AdminObservationsScreenState
    extends State<AdminObservationsScreen> {
  String _filter = 'Pending';

  final List<_Observation> _observations = [
    _Observation(
      title: 'Water accumulation on road',
      location: 'Masina',
      time: '10 minutes ago',
      status: 'Pending',
      icon: Icons.water,
    ),
    _Observation(
      title: 'Road blocked by flooding',
      location: 'N\'Djili',
      time: '18 minutes ago',
      status: 'Confirmed',
      icon: Icons.block,
    ),
    _Observation(
      title: 'Standing water near homes',
      location: 'Limete',
      time: '35 minutes ago',
      status: 'Pending',
      icon: Icons.home_work_outlined,
    ),
    _Observation(
      title: 'Flooding report',
      location: 'Masina',
      time: '1 hour ago',
      status: 'Rejected',
      icon: Icons.warning_amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _observations
        .where((item) => item.status == _filter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observations'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Citizen Observations',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and verify information submitted by residents.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in [
                          'Pending',
                          'Confirmed',
                          'Rejected',
                        ])
                          ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            onSelected: (_) {
                              setState(() {
                                _filter = filter;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (filtered.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'No observations in this category.',
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                        (observation) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _ObservationCard(
                              observation: observation,
                              onConfirm:
                                  observation.status == 'Pending'
                                      ? () => _updateObservation(
                                            observation,
                                            'Confirmed',
                                          )
                                      : null,
                              onReject:
                                  observation.status == 'Pending'
                                      ? () => _updateObservation(
                                            observation,
                                            'Rejected',
                                          )
                                      : null,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateObservation(
    _Observation observation,
    String status,
  ) {
    final index = _observations.indexOf(observation);

    if (index == -1) {
      return;
    }

    setState(() {
      _observations[index] = observation.copyWith(
        status: status,
      );
    });
  }
}

class _Observation {
  final String title;
  final String location;
  final String time;
  final String status;
  final IconData icon;

  const _Observation({
    required this.title,
    required this.location,
    required this.time,
    required this.status,
    required this.icon,
  });

  _Observation copyWith({
    String? status,
  }) {
    return _Observation(
      title: title,
      location: location,
      time: time,
      status: status ?? this.status,
      icon: icon,
    );
  }
}

class _ObservationCard extends StatelessWidget {
  final _Observation observation;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  const _ObservationCard({
    required this.observation,
    this.onConfirm,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Icon(observation.icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        observation.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${observation.location} • ${observation.time}',
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(observation.status),
                ),
              ],
            ),
            if (observation.status == 'Pending') ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                  FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}