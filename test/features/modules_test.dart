import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/router/app_router.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/home/domain/app_module.dart';
import 'package:mi_app_constructora/features/projects/application/project_scope.dart';

import '../helpers/test_helpers.dart';

/// Pruebas de las pantallas de módulo.
///
/// No comprueban el diseño de cada tarjeta —eso cambia—, sino lo que rompería
/// al usuario: que cada entrada del menú abra una pantalla de verdad, que las
/// que trabajan por obra pidan los datos de la obra elegida, y que ninguna
/// reviente cuando el backend devuelve una lista vacía.
void main() {
  /// Arranca la app en [location] con una sesión abierta.
  ///
  /// Devuelve las rutas que se pidieron, para poder afirmar sobre ellas.
  Future<List<String>> pumpModule(
    WidgetTester tester,
    String location, {
    String role = 'Administrador',
    http.Response Function(Uri url)? handler,
    bool withProjects = true,
  }) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InMemorySecureStore store = InMemorySecureStore();
    final ProviderContainer bootstrap = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient(
              (_) async => jsonResponse(loginResponse(role: role)),
            ),
          ),
        ),
      ],
    );
    addTearDown(bootstrap.dispose);
    await bootstrap
        .read(authControllerProvider.notifier)
        .login(email: 'andres@xyz.com', password: 'x', rememberMe: false);

    final List<String> paths = <String>[];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            tokenProvider: () => ref.read(authTokenProvider),
            httpClient: MockClient((http.Request request) async {
              paths.add(request.url.path);
              if (request.url.path == '/projects') {
                return jsonResponse(<Map<String, dynamic>>[
                  if (withProjects) projectJson(),
                ]);
              }
              return handler?.call(request.url) ??
                  jsonResponse(const <Object>[]);
            }),
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
    await tester.pumpAndSettle();

    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
    return paths;
  }

  group('cada módulo del menú abre su pantalla', () {
    for (final AppModule module in kAppModules) {
      testWidgets('${module.title} (${module.routePath})', (
        WidgetTester tester,
      ) async {
        await pumpModule(tester, module.routePath!);

        // El título de la barra basta como prueba de que se montó la pantalla
        // correcta: cada módulo usa el suyo.
        expect(
          find.text(module.title),
          findsWidgets,
          reason: '${module.routePath} debería mostrar «${module.title}»',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('módulos por obra', () {
    testWidgets('los gastos se piden para el proyecto activo', (
      WidgetTester tester,
    ) async {
      final List<String> paths = await pumpModule(tester, '/expenses');

      expect(paths, contains('/projects'));
      expect(paths, contains('/expenses/p1'));
    });

    testWidgets('el cronograma usa la obra activa', (
      WidgetTester tester,
    ) async {
      expect(await pumpModule(tester, '/schedule'), contains('/schedule/p1'));
    });

    testWidgets('las fotos usan la obra activa', (WidgetTester tester) async {
      expect(await pumpModule(tester, '/photos'), contains('/photos/p1'));
    });

    testWidgets('sin proyectos no se pide nada por obra', (
      WidgetTester tester,
    ) async {
      final List<String> paths = await pumpModule(
        tester,
        '/expenses',
        withProjects: false,
      );

      expect(find.text('Aún no hay proyectos'), findsOneWidget);
      expect(
        paths.where((String p) => p.startsWith('/expenses')),
        isEmpty,
        reason: 'sin obra elegida no hay a qué pedirle los gastos',
      );
    });

    testWidgets('cambiar de obra recarga el módulo abierto', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final InMemorySecureStore store = InMemorySecureStore();
      final ProviderContainer bootstrap = ProviderContainer(
        overrides: <Override>[
          secureStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWith(
            (Ref ref) => ApiClient(
              baseUrl: 'https://api.test',
              httpClient: MockClient(
                (_) async => jsonResponse(loginResponse()),
              ),
            ),
          ),
        ],
      );
      addTearDown(bootstrap.dispose);
      await bootstrap
          .read(authControllerProvider.notifier)
          .login(email: 'andres@xyz.com', password: 'x', rememberMe: false);

      final List<String> paths = <String>[];
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          secureStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWith(
            (Ref ref) => ApiClient(
              baseUrl: 'https://api.test',
              tokenProvider: () => ref.read(authTokenProvider),
              httpClient: MockClient((http.Request request) async {
                paths.add(request.url.path);
                if (request.url.path == '/projects') {
                  return jsonResponse(<Map<String, dynamic>>[
                    projectJson(),
                    projectJson(id: 'p2', name: 'Centro Comercial Norte'),
                  ]);
                }
                return jsonResponse(const <Object>[]);
              }),
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
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/expenses');
      await tester.pumpAndSettle();

      expect(paths, contains('/expenses/p1'));

      // La selección es una sola para toda la app, así que se puede cambiar
      // desde fuera del desplegable y el módulo abierto reacciona igual.
      container.read(selectedProjectIdProvider.notifier).state = 'p2';
      await tester.pumpAndSettle();

      expect(paths, contains('/expenses/p2'));
    });
  });

  testWidgets('un rol limitado no ve en el menú lo que no puede abrir', (
    WidgetTester tester,
  ) async {
    await pumpModule(tester, '/expenses', role: 'Contabilidad');

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Gastos'), findsWidgets);
    expect(find.text('Usuarios'), findsNothing);
    expect(find.text('Auditoría'), findsNothing);
  });
}
