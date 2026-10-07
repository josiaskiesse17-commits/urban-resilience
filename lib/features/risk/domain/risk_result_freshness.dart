import 'risk_result.dart';

class RiskResultFreshness {
  const RiskResultFreshness._();

  static const Duration maxAge = Duration(hours: 6);

  static bool needsUpdate(RiskResult? result, {DateTime? now}) {
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
