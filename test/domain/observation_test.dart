import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/features/observations/domain/observation.dart';

void main() {
  group('Observation.fromMap', () {
    test('parses a well-formed map', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);

      final observation = Observation.fromMap('obs-1', {
        'userId': 'user-1',
        'latitude': 5.3167,
        'longitude': -4.0333,
        'type': 'flooding',
        'mediaUrl': 'https://example.com/photo.png',
        'mediaType': 'image',
        'description': 'Une rue est inondée.',
        'status': 'verified',
        'createdAt': createdAt,
        'verifiedAt': null,
        'verifiedBy': null,
        'rejectionReason': null,
      });

      expect(observation.id, 'obs-1');
      expect(observation.userId, 'user-1');
      expect(observation.latitude, 5.3167);
      expect(observation.longitude, -4.0333);
      expect(observation.type, ObservationType.flooding);
      expect(observation.mediaType, ObservationMediaType.image);
      expect(observation.status, ObservationStatus.verified);
      expect(observation.createdAt, createdAt);
    });

    test('falls back to ObservationType.other for an unknown type', () {
      final observation = Observation.fromMap('obs-2', {
        'type': 'meteorite_strike',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(observation.type, ObservationType.other);
    });

    test('falls back to ObservationStatus.pending for an unknown status', () {
      final observation = Observation.fromMap('obs-3', {
        'type': 'flooding',
        'status': 'unknown_status',
        'createdAt': DateTime.now(),
      });

      expect(observation.status, ObservationStatus.pending);
    });

    test('leaves mediaType null when absent', () {
      final observation = Observation.fromMap('obs-4', {
        'type': 'flooding',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(observation.mediaType, isNull);
    });

    test('defaults latitude and longitude to 0 when missing', () {
      final observation = Observation.fromMap('obs-5', {
        'type': 'flooding',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(observation.latitude, 0);
      expect(observation.longitude, 0);
    });

    test('defaults createdAt to now when missing or unparsable', () {
      final before = DateTime.now();

      final observation = Observation.fromMap('obs-6', {
        'type': 'flooding',
        'status': 'pending',
      });

      final after = DateTime.now();

      expect(
        observation.createdAt.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        observation.createdAt.isBefore(
          after.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });

  group('Observation labels', () {
    test('typeLabel returns a French label for each type', () {
      final base = <String, dynamic>{
        'status': 'pending',
        'createdAt': DateTime.now(),
      };

      expect(
        Observation.fromMap('a', {...base, 'type': 'flooding'}).typeLabel,
        'Inondation',
      );
      expect(
        Observation.fromMap('b', {...base, 'type': 'blockedRoad'}).typeLabel,
        'Route bloquée',
      );
      expect(
        Observation.fromMap('c', {...base, 'type': 'landslide'}).typeLabel,
        'Glissement de terrain',
      );
      expect(
        Observation.fromMap('d', {...base, 'type': 'other'}).typeLabel,
        'Autre',
      );
    });

    test('statusLabel returns a French label for each status', () {
      final base = <String, dynamic>{
        'type': 'flooding',
        'createdAt': DateTime.now(),
      };

      expect(
        Observation.fromMap('a', {...base, 'status': 'pending'}).statusLabel,
        'En attente',
      );
      expect(
        Observation.fromMap('b', {...base, 'status': 'verified'}).statusLabel,
        'Validée',
      );
      expect(
        Observation.fromMap('c', {...base, 'status': 'rejected'}).statusLabel,
        'Rejetée',
      );
    });

    test('typeLabel uses the custom title for a custom type', () {
      final observation = Observation.fromMap('e', {
        'type': 'custom',
        'status': 'pending',
        'createdAt': DateTime.now(),
        'customTypeLabel': 'Fuite de gaz',
      });

      expect(observation.typeLabel, 'Fuite de gaz');
    });

    test('typeLabel falls back to "Autre" for a custom type without title', () {
      final observation = Observation.fromMap('f', {
        'type': 'custom',
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      expect(observation.typeLabel, 'Autre');
    });
  });
}
