#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

BRANCH=$(git branch --show-current)
if [[ "$BRANCH" != "feature/citizen-observations" ]]; then
  echo "ERREUR: branche actuelle: $BRANCH"
  echo "Bascule d'abord sur feature/citizen-observations."
  exit 1
fi

mkdir -p lib/features/observations/data \
         lib/features/observations/domain \
         lib/features/observations/presentation/providers

cat > lib/features/observations/domain/observation.dart <<'DART'
enum ObservationType {
  flooding,
  blockedRoad,
  landslide,
  other,
}

enum ObservationStatus {
  pending,
  verified,
  rejected,
}

enum ObservationMediaType {
  image,
  video,
}

class Observation {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final ObservationType type;
  final String? mediaUrl;
  final ObservationMediaType? mediaType;
  final String? description;
  final ObservationStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  const Observation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.mediaUrl,
    this.mediaType,
    this.description,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  factory Observation.fromMap(String id, Map<String, dynamic> map) {
    return Observation(
      id: id,
      userId: map['userId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      type: ObservationType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ObservationType.other,
      ),
      mediaUrl: map['mediaUrl'] as String?,
      mediaType: _mediaTypeFromValue(map['mediaType']),
      description: map['description'] as String?,
      status: ObservationStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => ObservationStatus.pending,
      ),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      verifiedAt: _dateFromValue(map['verifiedAt']),
      verifiedBy: map['verifiedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  static ObservationMediaType? _mediaTypeFromValue(dynamic value) {
    if (value == null) return null;
    return ObservationMediaType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ObservationMediaType.image,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return value.toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  String get typeLabel {
    switch (type) {
      case ObservationType.flooding:
        return 'Inondation';
      case ObservationType.blockedRoad:
        return 'Route bloquée';
      case ObservationType.landslide:
        return 'Glissement de terrain';
      case ObservationType.other:
        return 'Autre';
    }
  }

  String get statusLabel {
    switch (status) {
      case ObservationStatus.pending:
        return 'En attente';
      case ObservationStatus.verified:
        return 'Validée';
      case ObservationStatus.rejected:
        return 'Rejetée';
    }
  }
}
DART

cat > lib/features/observations/data/observations_repository.dart <<'DART'
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/observation.dart';

class ObservationsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  ObservationsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('observations');

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Vous devez être connecté pour effectuer cette action.');
    }
    return user;
  }

  Stream<List<Observation>> watchVerifiedObservations() {
    return _collection
        .where('status', isEqualTo: ObservationStatus.verified.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Observation.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Observation>> watchMyObservations() {
    final user = _requireUser();
    return _collection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Observation.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Observation>> watchPendingObservations() {
    return _collection
        .where('status', isEqualTo: ObservationStatus.pending.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Observation.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    return snapshot.data()?['role'] == 'admin';
  }

  Future<String> createObservation({
    required ObservationType type,
    required double latitude,
    required double longitude,
    String? description,
    File? mediaFile,
    ObservationMediaType? mediaType,
  }) async {
    final user = _requireUser();
    final document = _collection.doc();
    String? mediaUrl;

    if (mediaFile != null) {
      final extension = _extensionOf(mediaFile.path);
      final fileName = extension.isEmpty
          ? 'evidence'
          : 'evidence.$extension';
      final reference = _storage.ref(
        'observations/${user.uid}/${document.id}/$fileName',
      );
      final metadata = SettableMetadata(
        contentType: _contentType(mediaType, extension),
      );
      await reference.putFile(mediaFile, metadata);
      mediaUrl = await reference.getDownloadURL();
    }

    await document.set({
      'userId': user.uid,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType?.name,
      'description': description?.trim(),
      'status': ObservationStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'verifiedAt': null,
      'verifiedBy': null,
      'rejectionReason': null,
    });

    return document.id;
  }

  Future<void> verifyObservation(String observationId) async {
    final admin = _requireUser();
    if (!await isCurrentUserAdmin()) {
      throw StateError('Accès administrateur requis.');
    }

    await _collection.doc(observationId).update({
      'status': ObservationStatus.verified.name,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': admin.uid,
      'rejectionReason': null,
    });
  }

  Future<void> rejectObservation(
    String observationId, {
    String? reason,
  }) async {
    final admin = _requireUser();
    if (!await isCurrentUserAdmin()) {
      throw StateError('Accès administrateur requis.');
    }

    await _collection.doc(observationId).update({
      'status': ObservationStatus.rejected.name,
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': admin.uid,
      'rejectionReason': reason?.trim().isEmpty == true ? null : reason?.trim(),
    });
  }

  String _extensionOf(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) return '';
    return name.substring(index + 1).toLowerCase();
  }

  String _contentType(ObservationMediaType? type, String extension) {
    if (type == ObservationMediaType.video) {
      if (extension == 'mov') return 'video/quicktime';
      return 'video/mp4';
    }
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
DART

cat > lib/features/observations/presentation/providers/observations_providers.dart <<'DART'
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/observations_repository.dart';
import '../../domain/observation.dart';

final observationsRepositoryProvider = Provider<ObservationsRepository>((ref) {
  return ObservationsRepository();
});

final verifiedObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchVerifiedObservations();
});

final myObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchMyObservations();
});

final pendingObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchPendingObservations();
});

final isAdminProvider = FutureProvider<bool>((ref) {
  return ref.watch(observationsRepositoryProvider).isCurrentUserAdmin();
});
DART

cat > lib/features/observations/presentation/observations_screen.dart <<'DART'
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
      appBar: AppBar(title: const Text('Observations citoyennes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/observations/report'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Signaler'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(verifiedObservationsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Signalements vérifiés',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            verified.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Erreur : $error'),
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Aucun signalement vérifié.'),
                    )
                  : Column(
                      children: items.map(_observationCard).toList(),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mes signalements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            mine.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Erreur : $error'),
              data: (items) => items.isEmpty
                  ? const Text('Vous n’avez encore envoyé aucun signalement.')
                  : Column(
                      children: items.map(_myObservationCard).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _observationCard(Observation item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(item.typeLabel),
        subtitle: Text(
          item.description?.isNotEmpty == true
              ? item.description!
              : 'Position : ${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
        ),
      ),
    );
  }

  Widget _myObservationCard(Observation item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(_statusIcon(item.status)),
        title: Text(item.typeLabel),
        subtitle: Text(
          item.rejectionReason?.isNotEmpty == true
              ? '${item.statusLabel} — ${item.rejectionReason}'
              : item.statusLabel,
        ),
      ),
    );
  }

  IconData _statusIcon(ObservationStatus status) {
    switch (status) {
      case ObservationStatus.pending:
        return Icons.hourglass_top;
      case ObservationStatus.verified:
        return Icons.verified_outlined;
      case ObservationStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}
DART

cat > lib/features/observations/presentation/report_observation_screen.dart <<'DART'
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/observation.dart';
import 'providers/observations_providers.dart';

class ReportObservationScreen extends ConsumerStatefulWidget {
  const ReportObservationScreen({super.key});

  @override
  ConsumerState<ReportObservationScreen> createState() =>
      _ReportObservationScreenState();
}

class _ReportObservationScreenState
    extends ConsumerState<ReportObservationScreen> {
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  ObservationType _type = ObservationType.flooding;
  File? _mediaFile;
  ObservationMediaType? _mediaType;
  Position? _position;
  bool _loadingLocation = false;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final file = await _picker.pickMedia();
    if (file == null) return;

    final isVideo = file.mimeType?.startsWith('video/') ??
        RegExp(r'\.(mp4|mov|avi|mkv)$', caseSensitive: false)
            .hasMatch(file.path);

    setState(() {
      _mediaFile = File(file.path);
      _mediaType = isVideo
          ? ObservationMediaType.video
          : ObservationMediaType.image;
    });
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Activez la localisation de votre téléphone.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Permission de localisation refusée.');
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 10) {
      _showMessage('La description doit contenir au moins 10 caractères.');
      return;
    }
    if (_position == null) {
      _showMessage('Récupérez votre position GPS avant l’envoi.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(observationsRepositoryProvider).createObservation(
            type: _type,
            latitude: _position!.latitude,
            longitude: _position!.longitude,
            description: description,
            mediaFile: _mediaFile,
            mediaType: _mediaType,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Observation envoyée. Elle sera visible après validation par un administrateur.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Échec de l’envoi : $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau signalement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Votre signalement sera d’abord vérifié par un administrateur.',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<ObservationType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Type d’incident',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ObservationType.flooding,
                  child: Text('Inondation'),
                ),
                DropdownMenuItem(
                  value: ObservationType.blockedRoad,
                  child: Text('Route bloquée'),
                ),
                DropdownMenuItem(
                  value: ObservationType.landslide,
                  child: Text('Glissement de terrain'),
                ),
                DropdownMenuItem(
                  value: ObservationType.other,
                  child: Text('Autre'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez précisément la situation...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.perm_media_outlined),
              label: Text(
                _mediaFile == null
                    ? 'Ajouter une photo ou vidéo'
                    : 'Média sélectionné',
              ),
            ),
            if (_mediaFile != null) ...[
              const SizedBox(height: 8),
              Text(_mediaFile!.path.split(Platform.pathSeparator).last),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadingLocation ? null : _getLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                _position == null
                    ? 'Récupérer ma position GPS'
                    : 'Position GPS récupérée',
              ),
            ),
            if (_position != null) ...[
              const SizedBox(height: 8),
              Text(
                'Latitude : ${_position!.latitude.toStringAsFixed(6)}\n'
                'Longitude : ${_position!.longitude.toStringAsFixed(6)}',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Envoyer pour validation'),
            ),
          ],
        ),
      ),
    );
  }
}
DART

cat > lib/features/observations/presentation/admin_observations_screen.dart <<'DART'
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
DART

python3 - <<'PY'
from pathlib import Path
p=Path('lib/core/router/app_router.dart')
s=p.read_text()
imp="import '../../features/observations/presentation/admin_observations_screen.dart';\nimport '../../features/observations/presentation/report_observation_screen.dart';\n"
if imp not in s:
    s=s.replace("import '../../features/observations/presentation/observations_screen.dart';\n", "import '../../features/observations/presentation/observations_screen.dart';\n"+imp)
needle="""      GoRoute(\n        path: '/observations',\n        builder: (context, state) => const ObservationsScreen(),\n      ),\n"""
replacement=needle+"""      GoRoute(\n        path: '/observations/report',\n        builder: (context, state) => const ReportObservationScreen(),\n      ),\n      GoRoute(\n        path: '/admin/observations',\n        builder: (context, state) => const AdminObservationsScreen(),\n      ),\n"""
if "/observations/report" not in s:
    if needle not in s:
        raise SystemExit('Route /observations introuvable dans app_router.dart')
    s=s.replace(needle,replacement)
p.write_text(s)
PY

cat > firestore.rules <<'RULES'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return signedIn()
        && exists(/databases/$(database)/documents/users/$(request.auth.uid))
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{userId} {
      allow read: if signedIn() && (request.auth.uid == userId || isAdmin());
      allow create: if signedIn()
        && request.auth.uid == userId
        && request.resource.data.role == 'citizen';
      allow update: if signedIn()
        && request.auth.uid == userId
        && resource.data.role == request.resource.data.role
        && request.resource.data.role == 'citizen';
      allow delete: if isAdmin();
    }

    match /observations/{observationId} {
      allow read: if isAdmin()
        || (signedIn() && resource.data.userId == request.auth.uid)
        || resource.data.status == 'verified';

      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.status == 'pending'
        && request.resource.data.verifiedBy == null
        && request.resource.data.verifiedAt == null
        && request.resource.data.rejectionReason == null;

      allow update: if isAdmin()
        && resource.data.status == 'pending'
        && request.resource.data.userId == resource.data.userId
        && request.resource.data.status in ['verified', 'rejected']
        && request.resource.data.verifiedBy == request.auth.uid
        && request.resource.data.verifiedAt != null;

      allow delete: if isAdmin();
    }
  }
}
RULES

cat > storage.rules <<'RULES'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function signedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return signedIn()
        && firestore.exists(/databases/(default)/documents/users/$(request.auth.uid))
        && firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /observations/{userId}/{observationId}/{fileName} {
      allow write: if signedIn() && request.auth.uid == userId;
      allow read: if isAdmin()
        || (signedIn() && request.auth.uid == userId)
        || firestore.get(/databases/(default)/documents/observations/$(observationId)).data.status == 'verified';
    }
  }
}
RULES

python3 - <<'PY'
from pathlib import Path
p=Path('android/app/src/main/AndroidManifest.xml')
if p.exists():
    s=p.read_text()
    perms=[
      '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
      '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
    ]
    marker='<manifest '
    for perm in perms:
        if perm not in s:
            pos=s.find('>')
            s=s[:pos+1]+'\n    '+perm+s[pos+1:]
    p.write_text(s)
else:
    print('INFO: AndroidManifest.xml introuvable, ajoute les permissions GPS manuellement.')
PY

python3 - <<'PY'
from pathlib import Path
p=Path('firebase.json')
s=p.read_text()
import json
try:
    data=json.loads(s)
except Exception as e:
    raise SystemExit(f'firebase.json invalide: {e}')
data.setdefault('firestore', {})['rules']='firestore.rules'
data.setdefault('storage', {})['rules']='storage.rules'
p.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n')
PY

python3 -c "from pathlib import Path; p=Path('lib/features/auth/data/auth_repository.dart'); s=p.read_text(); s=s.replace(\"import 'package:firebase_auth/firebase_auth.dart';\", \"import 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\"); s=s.replace(\"    await user.updateDisplayName(displayName);\n    await user.sendEmailVerification();\", \"    await user.updateDisplayName(displayName);\n    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'email': email, 'displayName': displayName, 'role': 'citizen', 'createdAt': FieldValue.serverTimestamp()});\n    await user.sendEmailVerification();\"); p.write_text(s)"

flutter pub get
flutter analyze

echo
echo 'Implementation terminée. Vérifie ensuite les erreurs éventuelles ci-dessus.'
