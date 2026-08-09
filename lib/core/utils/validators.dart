/// Validadores de formularios. Devuelven `null` cuando el valor es válido,
/// que es lo que espera `TextFormField.validator`.
abstract final class Validators {
  /// Patrón de email deliberadamente permisivo: la validación real la hace el
  /// backend; aquí solo se atrapan errores obvios de tecleo.
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  /// Campo obligatorio.
  static String? required(
    String? value, {
    String message = 'Campo obligatorio',
  }) => (value == null || value.trim().isEmpty) ? message : null;

  /// Email obligatorio y con formato válido.
  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo electrónico';
    if (!_email.hasMatch(text)) return 'Correo electrónico inválido';
    return null;
  }

  /// Contraseña obligatoria con longitud mínima.
  static String? password(String? value, {int minLength = 6}) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Ingresa tu contraseña';
    if (text.length < minLength) {
      return 'Debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Número positivo opcional u obligatorio según [isRequired].
  static String? amount(String? value, {bool isRequired = true}) {
    final String text = value?.trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty) return isRequired ? 'Ingresa un monto' : null;
    final double? parsed = double.tryParse(text);
    if (parsed == null) return 'Monto inválido';
    if (parsed < 0) return 'El monto no puede ser negativo';
    return null;
  }
}
