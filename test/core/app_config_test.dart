import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app_constructora/core/config/app_config.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';

import '../helpers/test_helpers.dart';

void main() {
  // El orden importa: la primera prueba comprueba el comportamiento *antes*
  // de cargar el `.env`, y `dotenv` guarda estado global del proceso.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sin .env cargado se usan los valores por defecto', () {
    expect(AppConfig.apiBaseUrl, startsWith('https://'));
    expect(AppConfig.supabaseUrl, isEmpty);
    expect(AppConfig.hasSupabase, isFalse);
  });

  test('load() lee el .env de la raíz del proyecto', () async {
    await AppConfig.load();

    expect(
      AppConfig.apiBaseUrl,
      startsWith('https://'),
      reason: 'API_URL manda sobre el valor por defecto',
    );
    expect(AppConfig.supabaseUrl, contains('supabase.co'));
    expect(AppConfig.supabaseAnonKey, isNotEmpty);
    expect(AppConfig.hasSupabase, isTrue);
    expect(
      AppConfig.supabaseBucket,
      isNotEmpty,
      reason: 'si falta SUPABASE_BUCKET se usa "photos"',
    );
  });

  test('ApiClient apunta al host del .env cuando no se le pasa otro', () async {
    final List<RecordedRequest> requests = <RecordedRequest>[];
    final ApiClient api = ApiClient(
      httpClient: recordingClient(
        requests,
        (_) => jsonResponse(<String, dynamic>{}),
      ),
    );

    await api.getObject('/projects');

    expect(
      requests.single.url.toString(),
      '${AppConfig.apiBaseUrl}/projects',
      reason: 'todos los endpoints cuelgan de API_URL, sin prefijo /api',
    );
  });

  test('la URL base nunca acaba en barra', () {
    expect(AppConfig.apiBaseUrl.endsWith('/'), isFalse);
  });
}
