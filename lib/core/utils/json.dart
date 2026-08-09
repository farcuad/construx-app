import 'formatters.dart';

/// Lectura defensiva de los JSON de la API.
///
/// El backend omite campos opcionales, devuelve `null` en columnas vacías y a
/// veces manda números como cadena. Estas funciones evitan repetir el mismo
/// `as X? ?? valor` en cada modelo y garantizan que un campo inesperado nunca
/// tire la pantalla abajo.
abstract final class J {
  /// Texto, o cadena vacía si falta.
  static String str(Object? raw) => raw is String ? raw : '';

  /// Texto, o `null` si falta o viene vacío.
  static String? strOrNull(Object? raw) =>
      raw is String && raw.isNotEmpty ? raw : null;

  /// Entero tolerante a dobles y cadenas.
  static int intOf(Object? raw, [int fallback = 0]) => switch (raw) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? fallback,
    _ => fallback,
  };

  static int? intOrNull(Object? raw) => switch (raw) {
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };

  /// Decimal tolerante a enteros y cadenas (montos, cantidades…).
  static double dbl(Object? raw, [double fallback = 0]) =>
      Fmt.parseNum(raw) ?? fallback;

  static double? dblOrNull(Object? raw) => Fmt.parseNum(raw);

  /// Booleano tolerante a `1`/`0` y a `"true"`.
  static bool boolOf(Object? raw, {bool fallback = false}) => switch (raw) {
    final bool b => b,
    final num n => n != 0,
    'true' || '1' => true,
    'false' || '0' => false,
    _ => fallback,
  };

  /// Lista de objetos JSON. Devuelve una lista vacía si el campo falta o no es
  /// una lista, que es como el backend representa «sin elementos».
  static List<Map<String, dynamic>> objects(Object? raw) => raw is List
      ? raw.whereType<Map<String, dynamic>>().toList(growable: false)
      : const <Map<String, dynamic>>[];

  /// Lista de cadenas (p. ej. `permissions`).
  static List<String> strings(Object? raw) => raw is List
      ? raw.whereType<String>().toList(growable: false)
      : const <String>[];

  /// Convierte una lista de JSON en modelos con [parse].
  static List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
      objects(raw).map(parse).toList(growable: false);
}
