import '../i18n/sections/common_strings.dart';

/// Validadores de formularios. Devuelven `null` cuando el valor es válido,
/// que es lo que espera `TextFormField.validator`.
abstract final class Validators {
  /// Patrón de email deliberadamente permisivo: la validación real la hace el
  /// backend; aquí solo se atrapan errores obvios de tecleo.
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Mensajes en el idioma activo.
  ///
  /// Es estado global mutable, como el de [Fmt], y por la misma razón: los
  /// validadores se pasan como referencia a método (`validator:
  /// Validators.email`) y no pueden leer un provider. Solo lo escribe
  /// `LocaleController` al cambiar de idioma.
  static ValidationStrings messages = kCommonEs.validation;

  /// Campo obligatorio.
  static String? required(String? value, {String? message}) =>
      (value == null || value.trim().isEmpty)
      ? (message ?? messages.requiredField)
      : null;

  /// Email obligatorio y con formato válido.
  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return messages.emailEmpty;
    if (!_email.hasMatch(text)) return messages.emailInvalid;
    return null;
  }

  /// Contraseña obligatoria con longitud mínima.
  static String? password(String? value, {int minLength = 6}) {
    final String text = value ?? '';
    if (text.isEmpty) return messages.passwordEmpty;
    if (text.length < minLength) {
      return messages.passwordTooShort.replaceFirst('{n}', '$minLength');
    }
    return null;
  }

  /// Número positivo opcional u obligatorio según [isRequired].
  static String? amount(String? value, {bool isRequired = true}) {
    final String text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return isRequired ? messages.amountEmpty : null;
    final double? parsed = double.tryParse(text);
    if (parsed == null) return messages.amountInvalid;
    if (parsed < 0) return messages.amountNegative;
    return null;
  }
}
