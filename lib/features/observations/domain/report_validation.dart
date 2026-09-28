/// Règles de validation du formulaire de signalement.
///
/// Isolées de l'écran pour pouvoir être testées sans dépendre de Flutter,
/// de Firebase ou du GPS. Les messages et seuils reproduisent exactement
/// le comportement d'origine de l'écran.
class ReportValidation {
  const ReportValidation._();

  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 300;
  static const int minCustomTypeLength = 3;
  static const int maxCustomTypeLength = 60;

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

  /// Retourne un message d'erreur si l'utilisateur a choisi de saisir
  /// lui-même le type de risque (« Autre ») mais n'a pas donné de titre
  /// valide. Retourne `null` si un type prédéfini est utilisé, ou si le
  /// titre personnalisé est valide.
  static String? customTypeError({
    required bool isCustomType,
    required String customType,
  }) {
    if (!isCustomType) return null;

    final trimmed = customType.trim();

    if (trimmed.length < minCustomTypeLength) {
      return 'Précisez le type de risque '
          '(au moins $minCustomTypeLength caractères).';
    }

    if (trimmed.length > maxCustomTypeLength) {
      return 'Le titre du risque ne doit pas dépasser '
          '$maxCustomTypeLength caractères.';
    }

    return null;
  }
}
