import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración global de la aplicación.
///
/// Los valores salen del archivo `.env` de la raíz, que se empaqueta como
/// asset y se carga en el arranque con [load]. El orden de precedencia es:
///
/// 1. `--dart-define` (útil para builds de CI apuntando a otro entorno),
/// 2. el `.env`,
/// 3. el valor por defecto escrito aquí.
///
/// Como el `.env` viaja dentro del APK, **solo debe contener claves
/// publicables** (la `anon key` de Supabase lo es). Nunca una `service_role`
/// ni secretos de servidor: cualquiera puede descomprimir un APK.
abstract final class AppConfig {
  /// Lee el `.env`. Se llama una vez desde `main()`.
  ///
  /// Si el archivo falta, la app sigue arrancando con los valores por defecto
  /// en vez de morir en el primer frame.
  static Future<void> load() async {
    try {
      await dotenv.load();
    } on Object {
      // Sin `.env`: se usan los valores por defecto de esta clase.
    }
  }

  /// Valor de [key] en el `.env`, o [fallback] si no está o está vacío.
  static String _env(String key, [String fallback = '']) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.maybeGet(key);
    return value == null || value.isEmpty ? fallback : value;
  }

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const String _apiBaseUrlDefault =
      'https://dirs-api-erp-constructora.lunsoy.easypanel.host';

  /// URL base del backend (`API_URL` en el `.env`). **No** lleva prefijo
  /// `/api`: los endpoints cuelgan directamente del host.
  static String get apiBaseUrl => _apiBaseUrlOverride.isNotEmpty
      ? _apiBaseUrlOverride
      : _env('API_URL', _apiBaseUrlDefault);

  /// URL del proyecto de Supabase (`SUPABASE_URL`), donde se suben las fotos.
  static String get supabaseUrl => _env('SUPABASE_URL');

  /// Clave publicable de Supabase (`SUPABASE_ANON_KEY`).
  static String get supabaseAnonKey => _env('SUPABASE_ANON_KEY');

  /// Bucket de Storage donde viven las fotos de obra.
  static String get supabaseBucket => _env('SUPABASE_BUCKET', 'photos');

  /// `true` si hay configuración suficiente para subir archivos.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Tiempo máximo de espera para cada petición HTTP.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Las subidas de archivos necesitan más margen que una llamada JSON.
  static const Duration uploadTimeout = Duration(minutes: 2);

  /// Nombre visible de la aplicación.
  static const String appName = 'Construx';
}
