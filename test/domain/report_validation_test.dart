import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/features/observations/domain/report_validation.dart';

void main() {
  group('ReportValidation.descriptionError', () {
    test('rejects an empty description', () {
      expect(ReportValidation.descriptionError(''), isNotNull);
    });

    test('rejects a description under 10 characters', () {
      expect(ReportValidation.descriptionError('Court'), isNotNull);
    });

    test('trims whitespace before counting characters', () {
      // 8 visible characters padded with spaces should still fail.
      expect(ReportValidation.descriptionError('   abcd   '), isNotNull);
    });

    test('accepts a description of exactly the minimum length', () {
      final exact = 'a' * ReportValidation.minDescriptionLength;
      expect(ReportValidation.descriptionError(exact), isNull);
    });

    test('accepts a normal, valid description', () {
      expect(
        ReportValidation.descriptionError(
          'Une route est bloquée par un arbre tombé.',
        ),
        isNull,
      );
    });

    test('accepts a description of exactly the maximum length', () {
      final exact = 'a' * ReportValidation.maxDescriptionLength;
      expect(ReportValidation.descriptionError(exact), isNull);
    });

    test('rejects a description over the maximum length', () {
      final tooLong = 'a' * (ReportValidation.maxDescriptionLength + 1);
      expect(ReportValidation.descriptionError(tooLong), isNotNull);
    });
  });

  group('ReportValidation.positionError', () {
    test('returns an error when there is no position', () {
      expect(
        ReportValidation.positionError(hasPosition: false),
        isNotNull,
      );
    });

    test('returns null when a position is present', () {
      expect(
        ReportValidation.positionError(hasPosition: true),
        isNull,
      );
    });
  });
}
