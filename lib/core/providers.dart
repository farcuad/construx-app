import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import 'network/api_client.dart';
import 'storage/secure_store.dart';

/// Almacenamiento cifrado del dispositivo.
///
/// Se sobreescribe en los tests con [InMemorySecureStore] mediante
/// `ProviderScope(overrides: ...)`.
final Provider<SecureStore> secureStoreProvider = Provider<SecureStore>(
  (Ref ref) => FlutterSecureStore(),
);

/// Token JWT vigente, expuesto como valor simple para que [apiClientProvider]
/// no dependa del controlador de auth (evita un ciclo de providers).
final StateProvider<String?> authTokenProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Se emite cuando el backend responde 401 en una petición autenticada.
///
/// El `AuthController` lo escucha para cerrar la sesión y volver al login.
final StateProvider<int> sessionExpiredSignalProvider = StateProvider<int>(
  (Ref ref) => 0,
);

/// Cliente HTTP compartido por toda la app.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final ApiClient client = ApiClient(
    tokenProvider: () => ref.read(authTokenProvider),
    onUnauthorized: () {
      // `read` en lugar de `watch`: esto ocurre fuera de la fase de build.
      ref.read(sessionExpiredSignalProvider.notifier).state++;
    },
  );
  ref.onDispose(client.close);
  return client;
});

/// Repositorio de autenticación.
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  ),
);
