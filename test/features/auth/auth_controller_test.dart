import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late InMemorySecureStore store;

  /// Contenedor con el almacén en memoria y un cliente HTTP falso.
  ProviderContainer buildContainer(http.Client client) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: client,
            tokenProvider: () => ref.read(authTokenProvider),
            onUnauthorized: () =>
                ref.read(sessionExpiredSignalProvider.notifier).state++,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => store = InMemorySecureStore());

  test('arranca en estado "restoring"', () {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(null)),
    );

    expect(container.read(authControllerProvider).status, AuthStatus.restoring);
  });

  test('restore sin sesión guardada deja al usuario sin autenticar', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(null)),
    );

    await container.read(authControllerProvider.notifier).restore();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(authTokenProvider), isNull);
  });

  test('un login correcto autentica y publica el token', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(loginResponse())),
    );

    final bool ok = await container
        .read(authControllerProvider.notifier)
        .login(
          email: 'andres@xyz.com',
          password: 'claveSegura123',
          rememberMe: false,
        );

    final AuthState state = container.read(authControllerProvider);
    expect(ok, isTrue);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.name, 'Andrés Pérez');
    expect(state.isSubmitting, isFalse);
    expect(state.errorMessage, isNull);
    expect(container.read(authTokenProvider), state.session!.token);
  });

  test('un login fallido expone el mensaje del backend', () async {
    final ProviderContainer container = buildContainer(
      MockClient(
        (_) async => jsonResponse(
          <String, String>{'message': 'Credenciales Incorrectas'},
          status: 401,
        ),
      ),
    );

    final bool ok = await container
        .read(authControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'mala', rememberMe: false);

    final AuthState state = container.read(authControllerProvider);
    expect(ok, isFalse);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, 'Credenciales Incorrectas');
    expect(state.isSubmitting, isFalse);
  });

  test('un fallo de red produce un mensaje legible', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => throw http.ClientException('sin red')),
    );

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'x', rememberMe: false);

    expect(
      container.read(authControllerProvider).errorMessage,
      contains('Sin conexión'),
    );
  });

  test('clearError limpia el mensaje del formulario', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => http.Response('error', 500)),
    );

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'x', rememberMe: false);
    expect(container.read(authControllerProvider).errorMessage, isNotNull);

    container.read(authControllerProvider.notifier).clearError();
    expect(container.read(authControllerProvider).errorMessage, isNull);
  });

  test('el login recuerda las credenciales cuando se marca la casilla', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(loginResponse())),
    );

    await container
        .read(authControllerProvider.notifier)
        .login(
          email: 'andres@xyz.com',
          password: 'claveSegura123',
          rememberMe: true,
        );

    expect(store.snapshot[StorageKeys.rememberMe], '1');
    expect(store.snapshot[StorageKeys.rememberedEmail], 'andres@xyz.com');
  });

  test('logout limpia la sesión pero conserva lo recordado', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(loginResponse())),
    );
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await controller.login(
      email: 'andres@xyz.com',
      password: 'clave',
      rememberMe: true,
    );
    await controller.logout();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(container.read(authTokenProvider), isNull);
    expect(store.snapshot.containsKey(StorageKeys.token), isFalse);
    expect(store.snapshot[StorageKeys.rememberedEmail], 'andres@xyz.com');
  });

  test('logout con forgetCredentials olvida los datos recordados', () async {
    final ProviderContainer container = buildContainer(
      MockClient((_) async => jsonResponse(loginResponse())),
    );
    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );

    await controller.login(
      email: 'andres@xyz.com',
      password: 'clave',
      rememberMe: true,
    );
    await controller.logout(forgetCredentials: true);

    expect(store.snapshot.containsKey(StorageKeys.rememberedEmail), isFalse);
  });

  test('un 401 en una petición autenticada cierra la sesión', () async {
    // El login funciona; cualquier petición posterior devuelve 401.
    bool loggedIn = false;
    final ProviderContainer container = buildContainer(
      MockClient((http.Request request) async {
        if (request.url.path == '/login') {
          loggedIn = true;
          return jsonResponse(loginResponse());
        }
        return textResponse('Token inválido o expirado', status: 401);
      }),
    );

    final AuthController controller = container.read(
      authControllerProvider.notifier,
    );
    await controller.login(
      email: 'andres@xyz.com',
      password: 'clave',
      rememberMe: false,
    );
    expect(loggedIn, isTrue);
    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );

    // Petición autenticada que caduca.
    await expectLater(
      container.read(apiClientProvider).getList('/projects'),
      throwsA(anything),
    );
    // El cierre de sesión se dispara desde un listener asíncrono.
    await Future<void>.delayed(Duration.zero);

    final AuthState state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.errorMessage, contains('sesión expiró'));
  });

  test('restore recupera una sesión previamente guardada', () async {
    final ProviderContainer first = buildContainer(
      MockClient((_) async => jsonResponse(loginResponse())),
    );
    await first
        .read(authControllerProvider.notifier)
        .login(email: 'andres@xyz.com', password: 'clave', rememberMe: false);

    // Nuevo contenedor = app reabierta, mismo almacenamiento cifrado.
    final ProviderContainer second = buildContainer(
      MockClient((_) async => jsonResponse(null)),
    );
    await second.read(authControllerProvider.notifier).restore();

    final AuthState state = second.read(authControllerProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, 'andres@xyz.com');
    expect(second.read(authTokenProvider), isNotNull);
  });
}
