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
    String? customTypeLabel,
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
      if (!await mediaFile.exists()) {
        throw StateError(
          'Le fichier sélectionné est introuvable. Reprenez la photo.',
        );
      }

      final snapshot = await reference.putFile(mediaFile, metadata);
      if (snapshot.state != TaskState.success) {
        throw StateError('Le téléversement du média a échoué.');
      }
      mediaUrl = await snapshot.ref.getDownloadURL();
    }

    await document.set({
      'userId': user.uid,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType?.name,
      'description': description?.trim(),
      'customTypeLabel': type == ObservationType.custom
          ? customTypeLabel?.trim()
          : null,
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
