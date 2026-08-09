import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/clients/presentation/clients_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/widgets/app_drawer.dart';
import 'package:mi_app_constructora/features/projects/presentation/projects_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  /// Arranca la app con sesión iniciada y abre el menú lateral.
  ///
  /// La pantalla de pruebas se agranda a propósito: el menú lista los 18
  /// módulos y en 800×600 la mitad quedaría fuera del viewport, sin construir.
  Future<void> pumpWithDrawerOpen(
    WidgetTester tester, {
    List<String> permissions = const <String>['*'],
    String role = 'Administrador',
  }) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InMemorySecureStore store = InMemorySecureStore();

    // Se siembra la sesión con un login real contra el HTTP simulado, para que
    // el almacén quede exactamente como tras un inicio de sesión de verdad.
    final ProviderContainer bootstrap = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient(
              (_) async => jsonResponse(
                loginResponse(role: role, permissions: permissions),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(bootstrap.dispose);
    await bootstrap
        .read(authControllerProvider.notifier)
        .login(email: 'andres@xyz.com', password: 'x', rememberMe: false);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient((_) async => jsonResponse(null)),
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
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
  }

  /// Acota el finder al menú: los mismos títulos están en la rejilla del panel.
  Finder inDrawer(String label) => find.descendant(
    of: find.byType(AppDrawer),
    matching: find.text(label),
  );

  testWidgets('el botón de menú abre el cajón desde el panel', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(tester);

    expect(find.byType(AppDrawer), findsOneWidget);
    expect(inDrawer('Panel'), findsOneWidget);
  });

  testWidgets('lista todos los módulos del panel y quién ha iniciado sesión', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(tester);

    // Módulos con pantalla…
    expect(inDrawer('Proyectos'), findsOneWidget);
    expect(inDrawer('Clientes'), findsOneWidget);
    // …y módulos aún sin implementar, marcados como tales.
    expect(inDrawer('Inventario'), findsOneWidget);
    expect(inDrawer('Usuarios'), findsOneWidget);
    expect(inDrawer('Pronto'), findsWidgets);

    expect(inDrawer('Andrés Pérez'), findsOneWidget);
    expect(inDrawer('Administrador'), findsOneWidget);
  });

  testWidgets('un rol limitado solo ve sus módulos en el menú', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(
      tester,
      role: 'Supervisor',
      permissions: const <String>['projects:read', 'inventory:read'],
    );

    expect(inDrawer('Panel'), findsOneWidget);
    expect(inDrawer('Proyectos'), findsOneWidget);
    expect(inDrawer('Inventario'), findsOneWidget);
    expect(inDrawer('Clientes'), findsNothing);
    expect(inDrawer('Usuarios'), findsNothing);
    expect(inDrawer('Facturación'), findsNothing);
  });

  testWidgets('tocar un módulo disponible navega y cierra el menú', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(tester);

    await tester.tap(inDrawer('Clientes'));
    await tester.pumpAndSettle();

    expect(find.byType(ClientsScreen), findsOneWidget);
    expect(find.byType(AppDrawer), findsNothing, reason: 'el cajón se cierra');
  });

  testWidgets('tocar un módulo sin pantalla avisa y no navega', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(tester);

    await tester.tap(inDrawer('Presupuestos'));
    await tester.pumpAndSettle();

    expect(find.text('Presupuestos: módulo en construcción'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('el menú también está disponible dentro de un módulo', (
    WidgetTester tester,
  ) async {
    await pumpWithDrawerOpen(tester);

    await tester.tap(inDrawer('Proyectos'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectsScreen), findsOneWidget);

    // Sin flecha de volver: la barra pone sola el botón del cajón.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.byType(AppDrawer), findsOneWidget);
    await tester.tap(inDrawer('Panel'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
