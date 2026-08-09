import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/auth/presentation/login_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';

import 'helpers/test_helpers.dart';

void main() {
  /// Monta la app completa con almacenamiento en memoria y HTTP simulado.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required SecureStore store,
    required http.Client client,
  }) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: client,
            tokenProvider: () => ref.read(authTokenProvider),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ConstructoraApp(),
      ),
    );
    return container;
  }

  testWidgets('sin sesión guardada arranca en el login', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      store: InMemorySecureStore(),
      client: MockClient((_) async => jsonResponse(null)),
    );

    // Primer frame: splash mientras se restaura la sesión.
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Recordar datos'), findsOneWidget);
  });

  testWidgets('con sesión vigente entra directo al panel', (
    WidgetTester tester,
  ) async {
    final InMemorySecureStore store = InMemorySecureStore();
    // Se siembra la sesión mediante un login previo con el mismo almacén.
    final ProviderContainer bootstrap = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient((_) async => jsonResponse(loginResponse())),
          ),
        ),
      ],
    );
    addTearDown(bootstrap.dispose);
    await bootstrap
        .read(authControllerProvider.notifier)
        .login(email: 'andres@xyz.com', password: 'x', rememberMe: false);

    await pumpApp(
      tester,
      store: store,
      // El panel no pide datos: los módulos se listan desde los permisos.
      client: MockClient((_) async => jsonResponse(null)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Andrés Pérez'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('el panel es el tablero financiero, no la rejilla de módulos', (
    WidgetTester tester,
  ) async {
    final InMemorySecureStore store = InMemorySecureStore();
    final ProviderContainer bootstrap = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient((_) async => jsonResponse(loginResponse())),
          ),
        ),
      ],
    );
    addTearDown(bootstrap.dispose);
    await bootstrap
        .read(authControllerProvider.notifier)
        .login(email: 'andres@xyz.com', password: 'x', rememberMe: false);

    await pumpApp(
      tester,
      store: store,
      client: MockClient((http.Request request) async {
        if (request.url.path == '/projects') {
          return jsonResponse(<Map<String, dynamic>>[projectJson()]);
        }
        if (request.url.path.startsWith('/dashboard/financial/')) {
          return jsonResponse(kpisJson());
        }
        return jsonResponse(null);
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Presupuesto total'), findsOneWidget);
    expect(find.text('Variación financiera'), findsOneWidget);
    // Los módulos se movieron al menú lateral: aquí ya no salen.
    expect(find.text('Próximamente'), findsNothing);
  });
}
