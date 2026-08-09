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
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/widgets/app_drawer.dart';
import 'package:mi_app_constructora/features/notifications/presentation/widgets/notifications_bell.dart';
import 'package:mi_app_constructora/features/notifications/presentation/widgets/notifications_panel.dart';

import '../../helpers/test_helpers.dart';

/// Aviso tal y como lo devuelve `GET /notifications`.
Map<String, dynamic> notificationJson({
  String id = 'n1',
  String title = 'Orden de compra pendiente',
  bool isRead = false,
  String priority = 'high',
}) => <String, dynamic>{
  'id': id,
  'title': title,
  'message': 'Requiere tu aprobación',
  'type': 'purchase',
  'priority': priority,
  'is_read': isRead,
  'created_at': '2026-08-09T10:00:00Z',
};

void main() {
  /// Arranca la app con sesión iniciada en el panel.
  Future<List<String>> pumpHome(
    WidgetTester tester, {
    List<String> permissions = const <String>['*'],
    List<Map<String, dynamic>> inbox = const <Map<String, dynamic>>[],
    void Function(ProviderContainer container)? onReady,
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
              (_) async =>
                  jsonResponse(loginResponse(permissions: permissions)),
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
              if (request.url.path == '/notifications') {
                return jsonResponse(inbox);
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
    onReady?.call(container);
    await tester.pumpAndSettle();
    return paths;
  }

  testWidgets('la campana vive en la cabecera del panel, no en el menú', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.byType(NotificationsBell), findsOneWidget);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(
      find.text('Avisos'),
      findsNothing,
      reason: 'los avisos se abren desde la campana, no desde el menú',
    );
    expect(
      kAppModules.where((AppModule m) => m.id == 'notifications'),
      isEmpty,
    );
  });

  testWidgets('cerrar sesión no está ni en la cabecera ni en el menú', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    // Ahora vive en Ajustes, a un toque en la barra inferior.
    expect(find.byTooltip('Cerrar sesión'), findsNothing);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppDrawer),
        matching: find.text('Cerrar sesión'),
      ),
      findsNothing,
    );
    // El pie del menú sigue diciendo quién ha iniciado sesión.
    expect(find.text('Andrés Pérez'), findsWidgets);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('el distintivo cuenta solo los avisos sin leer', (
    WidgetTester tester,
  ) async {
    final List<String> paths = await pumpHome(
      tester,
      inbox: <Map<String, dynamic>>[
        notificationJson(),
        notificationJson(id: 'n2', title: 'Factura vencida'),
        notificationJson(id: 'n3', title: 'Ya visto', isRead: true),
      ],
    );

    expect(paths, contains('/notifications'));
    expect(find.text('2'), findsOneWidget);
    expect(find.byTooltip('2 avisos sin leer'), findsOneWidget);
  });

  testWidgets('sin avisos pendientes no hay distintivo', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      inbox: <Map<String, dynamic>>[notificationJson(isRead: true)],
    );

    expect(find.byTooltip('Avisos'), findsOneWidget);
  });

  testWidgets('la campana abre un cuadro, no una pantalla', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, inbox: <Map<String, dynamic>>[notificationJson()]);

    await tester.tap(find.byType(NotificationsBell));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPanel), findsOneWidget);
    expect(find.text('Orden de compra pendiente'), findsOneWidget);
    // Lo importante del cuadro: el panel sigue debajo, no se ha navegado.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('el cuadro se cierra y devuelve la pantalla de antes', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, inbox: <Map<String, dynamic>>[notificationJson()]);

    await tester.tap(find.byType(NotificationsBell));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsPanel), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('la campana también está en la barra de los módulos', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      inbox: <Map<String, dynamic>>[notificationJson()],
      onReady: (ProviderContainer container) =>
          container.read(routerProvider).go('/suppliers'),
    );

    expect(find.byType(NotificationsBell), findsOneWidget);
    expect(
      find.text('1'),
      findsOneWidget,
      reason: 'el contador es el mismo en todas las pantallas',
    );
  });

  testWidgets('sin permiso no hay campana ni petición a la bandeja', (
    WidgetTester tester,
  ) async {
    final List<String> paths = await pumpHome(
      tester,
      permissions: const <String>['projects:read', 'dashboard:read'],
    );

    expect(find.byType(NotificationsBell), findsOneWidget);
    expect(
      find.byIcon(Icons.notifications_none_rounded),
      findsNothing,
      reason: 'el widget se monta pero no pinta nada sin «notifications:read»',
    );
    expect(
      paths,
      isNot(contains('/notifications')),
      reason: 'pedir la bandeja sin permiso sería un 403 en cada arranque',
    );
  });
}
