import 'dart:ui' show Locale;

/// Idiomas que ofrece la aplicación.
///
/// El [code] es lo que se guarda en el dispositivo y lo que se le pasa a
/// `intl` para formatear fechas y montos, así que debe coincidir con un idioma
/// que `flutter_localizations` sepa resolver.
enum AppLanguage {
  es('es', 'Español'),
  pt('pt', 'Português'),
  en('en', 'English');

  const AppLanguage(this.code, this.label);

  /// Código ISO 639-1.
  final String code;

  /// Nombre del idioma **en ese idioma**: quien busca «Português» no debería
  /// tener que reconocerlo escrito en español.
  final String label;

  Locale get locale => Locale(code);

  /// Idioma por defecto mientras no haya una elección guardada.
  static const AppLanguage fallback = AppLanguage.es;

  /// Lo que se le declara a `MaterialApp`. Es una constante, y no un `map`
  /// sobre [values], para no reconstruir la lista en cada `build`.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('pt'),
    Locale('en'),
  ];

  /// El idioma de [code], o `null` si no lo ofrecemos.
  static AppLanguage? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final AppLanguage language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
