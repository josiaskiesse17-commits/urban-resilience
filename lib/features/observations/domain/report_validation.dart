/// Règles de validation du formulaire de signalement.
///
/// Isolées de l'écran pour pouvoir être testées sans dépendre de Flutter,
/// de Firebase ou du GPS. Les messages et seuils reproduisent exactement
/// le comportement d'origine de l'écran.
class ReportValidation {
  const ReportValidation._();

  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 300;

  /// Retourne un message d'erreur si la description est invalide,
  /// ou `null` si elle est acceptable.
  static String? descriptionError(String description) {
    final trimmed = description.trim();

    if (trimmed.length < minDescriptionLength) {
      return 'La description doit contenir au moins '
          '$minDescriptionLength caractères.';
    }

    if (trimmed.length > maxDescriptionLength) {
      return 'La description ne doit pas dépasser '
          '$maxDescriptionLength caractères.';
    }

    return null;
  }

  /// Retourne un message d'erreur si aucune position GPS n'est disponible,
  /// ou `null` si la position est présente.
  static String? positionError({required bool hasPosition}) {
    if (!hasPosition) {
      return 'Récupérez votre position avant l’envoi.';
    }
    return null;
  }
}
