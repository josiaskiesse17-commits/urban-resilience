import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/domain/risk_alert.dart';
import '../../../alerts/presentation/alert_presentation.dart';
import '../../../alerts/presentation/providers/alert_providers.dart';
import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/hazard_type.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';

class AdminAlertsScreen extends ConsumerStatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  ConsumerState<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends ConsumerState<AdminAlertsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _zoneId;
  HazardType _hazard = HazardType.flooding;
  AlertSeverity _severity = AlertSeverity.warning;
  DateTime? _expiresAt;
  bool _publishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_expiresAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date d’expiration est obligatoire.')),
      );
      return;
    }

    final expiry = _expiresAt!.toUtc();

    if (!expiry.isAfter(DateTime.now().toUtc())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date d’expiration doit être dans le futur.'),
        ),
      );
      return;
    }

    final zones = ref.read(riskZoneCatalogProvider);
    final zoneId = _zoneId ?? (zones.isEmpty ? null : zones.first.id);

    if (zoneId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune zone disponible.')));
      return;
    }

    final zone = RiskZoneCatalog.byId(zoneId);

    if (zone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone sélectionnée introuvable.')),
      );
      return;
    }

    setState(() => _publishing = true);

    try {
      final repository = ref.read(alertsRepositoryProvider);

      final alert = RiskAlert(
        id: repository.newId(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        zoneId: zone.id,
        hazardType: _hazard.label,
        severity: _severity,
        latitude: zone.latitude,
        longitude: zone.longitude,
        createdAt: DateTime.now().toUtc(),
        expiresAt: expiry,
      );

      await repository.create(alert);

      _titleController.clear();
      _messageController.clear();

      if (mounted) {
        setState(() => _expiresAt = null);

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Alerte publiée.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publication impossible : $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initialDate = _expiresAt != null && _expiresAt!.isAfter(now)
        ? _expiresAt!
        : now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date d’expiration',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final initialTime = _expiresAt != null
        ? TimeOfDay.fromDateTime(_expiresAt!.toLocal())
        : const TimeOfDay(hour: 23, minute: 59);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Heure d’expiration',
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!selected.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La date et l’heure d’expiration doivent être dans le futur.',
          ),
        ),
      );
      return;
    }

    setState(() => _expiresAt = selected);
  }

   Future<void> _deleteAlert(RiskAlert alert) async {
     final confirmed = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Supprimer l’alerte ?'),
         content: SingleChildScrollView(
           child: ConstrainedBox(
             constraints: BoxConstraints(
               maxWidth: MediaQuery.sizeOf(context).width * 0.9 > 600 ? 600 : MediaQuery.sizeOf(context).width * 0.9,
             ),
             child: Text(
               'L’alerte « ${alert.title} » sera supprimée définitivement.',
             ),
           ),
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: const Text('Annuler'),
           ),
           FilledButton(
             onPressed: () => Navigator.pop(context, true),
             child: const Text('Supprimer'),
           ),
         ],
       ),
     );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(alertsRepositoryProvider).delete(id: alert.id);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Alerte supprimée.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suppression impossible : $error')),
        );
      }
    }
  }

   @override
   Widget build(BuildContext context) {
     final zones = ref.watch(riskZoneCatalogProvider);

     if (_zoneId == null && zones.isNotEmpty) {
       _zoneId = zones.first.id;
     }

     return Scaffold(
       appBar: AppBar(title: const Text('Alertes')),
       body: SingleChildScrollView(
         padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0),
         child: Center(
           child: ConstrainedBox(
             constraints: const BoxConstraints(maxWidth: 1200),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 _buildHeader(context),
                 const SizedBox(height: 20),
                 _buildCreateCard(context, zones),
                 const SizedBox(height: 20),
                 _buildAlertsList(context),
               ],
             ),
           ),
         ),
       ),
     );
   }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des alertes',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Créez et publiez manuellement les alertes affichées aux '
          'utilisateurs.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCreateCard(BuildContext context, List<RiskZoneTarget> zones) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Créer une alerte',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l’alerte',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le titre est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _zoneId,
                decoration: const InputDecoration(
                  labelText: 'Zone',
                  border: OutlineInputBorder(),
                ),
                items: zones
                    .map(
                      (zone) => DropdownMenuItem(
                        value: zone.id,
                        child: Text(zone.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() => _zoneId = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<HazardType>(
                initialValue: _hazard,
                decoration: const InputDecoration(
                  labelText: 'Risque',
                  border: OutlineInputBorder(),
                ),
                items: HazardType.values
                    .map(
                      (hazard) => DropdownMenuItem(
                        value: hazard,
                        child: Text(hazard.labelFr),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() => _hazard = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AlertSeverity>(
                initialValue: _severity,
                decoration: const InputDecoration(
                  labelText: 'Gravité',
                  border: OutlineInputBorder(),
                ),
                items: AlertSeverity.values
                    .map(
                      (severity) => DropdownMenuItem(
                        value: severity,
                        child: Text(alertSeverityLabel(severity)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() => _severity = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le message est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickExpiry,
                      icon: const Icon(Icons.event, size: 18),
                      label: Text(
                        _expiresAt == null
                            ? 'Définir l’expiration'
                            : 'Expire le ${_formatDateTime(_expiresAt!)}',
                      ),
                    ),
                  ),
                  if (_expiresAt != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Retirer l’expiration',
                      onPressed: () {
                        setState(() => _expiresAt = null);
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_alert),
                label: Text(_publishing ? 'Publication...' : 'Publier'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context) {
    final alerts = ref.watch(allAlertsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Historique des alertes',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            alerts.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Erreur : $error'),
              data: (items) => items.isEmpty
                  ? const Text('Aucune alerte publiée pour le moment.')
                  : Column(
                      children: [
                        for (final alert in items)
                          _AlertListTile(
                            alert: alert,
                            onToggle: (active) => _setActive(alert, active),
                            onDelete: () => _deleteAlert(alert),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setActive(RiskAlert alert, bool active) async {
    try {
      await ref
          .read(alertsRepositoryProvider)
          .setActive(id: alert.id, active: active);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active ? 'Alerte publiée.' : 'Alerte retirée des utilisateurs.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
      }
    }
  }

  static String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _AlertListTile extends StatelessWidget {
  const _AlertListTile({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  final RiskAlert alert;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final zoneName = RiskZoneCatalog.byId(alert.zoneId)?.name ?? alert.zoneId;

    final hazardLabel =
        HazardType.fromLabel(alert.hazardType)?.labelFr ?? alert.hazardType;

    final color = alertSeverityColor(alert.severity);

    final subtitle = alert.isExpired
        ? '$zoneName • $hazardLabel • Expirée'
        : '$zoneName • $hazardLabel • '
              '${_AdminAlertsScreenState._formatDateTime(alert.createdAt)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        alert.active && !alert.isExpired
            ? Icons.notifications_active
            : Icons.notifications_none,
        color: color,
      ),
      title: Text(alert.title),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(label: Text(alertSeverityLabel(alert.severity))),
          Switch(
            value: alert.active,
            onChanged: alert.isExpired ? null : onToggle,
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
