import 'risk_result.dart';

/// Decides whether a stored [RiskResult] can still be used as-is or must be
/// rebuilt by the Risk Intelligence pipeline.
///
/// The stored result doubles as the cache of the pipeline: the historical
/// baseline and the live environmental lookups are only replayed when there
/// is no result yet, or when the stored one is older than [maxAge]. This is
/// what keeps a screen rebuild from triggering another (expensive) run.
class RiskResultFreshness {
  const RiskResultFreshness._();

  /// Maximum age of a stored result before it is considered out of date.
  static const Duration maxAge = Duration(hours: 6);

  static bool needsUpdate(
    RiskResult? result, {
    DateTime? now,
  }) {
    if (result == null) {
      return true;
    }

    final reference = (now ?? DateTime.now()).toUtc();
    final updatedAt = result.updatedAt.toUtc();

    if (updatedAt.isAfter(reference)) {
      return false;
    }

    return reference.difference(updatedAt) > maxAge;
  }
}
