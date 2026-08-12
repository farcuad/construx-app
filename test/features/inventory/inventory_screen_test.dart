import 'dart:convert';

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

import '../../helpers/test_helpers.dart';

void main() {
  /// Abre el módulo de inventario con sesión iniciada.
  Future<List<http.Request>> pumpInventory(
    WidgetTester tester, {
    required String role,
  }) async {
    tester.view.physicalSize = const Size(1000, 2200);
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

    final List<http.Request> requests = <http.Request>[];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient((http.Request request) async {
              requests.add(request);
              switch (request.url.path) {
                case '/projects':
                  return jsonResponse(<Map<String, dynamic>>[projectJson()]);
                case '/warehouses':
                  return jsonResponse(<Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'w1',
                      'name': 'Almacén Central',
                      'project_id': 'p1',
                      'location': 'Sector A',
                    },
                  ]);
                case '/materials':
                  return jsonResponse(<Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'm1',
                      'name': 'Cemento gris',
                      'code': 'CEM-1',
                      'unit': 'saco',
                    },
                  ]);
                case '/inventory/stock/w1':
                  return jsonResponse(<Map<String, dynamic>>[
                    <String, dynamic>{
                      'material_id': 'm1',
                      'material_name': 'Cemento gris',
                      'code': 'CEM-1',
                      'unit': 'saco',
                      'quantity': 40,
                    },
                  ]);
                default:
                  return jsonResponse(<String, dynamic>{'id': 'x'});
              }
            }),
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

    container.read(routerProvider).go('/inventory');
    await tester.pumpAndSettle();
    return requests;
  }

  testWidgets('almacén ve las dos acciones de cada bodega', (
    WidgetTester tester,
  ) async {
    await pumpInventory(tester, role: 'Almacén');

    expect(find.text('Almacén Central'), findsOneWidget);
    expect(find.byTooltip('Registrar movimiento'), findsOneWidget);
    expect(find.byTooltip('Ver materiales'), findsOneWidget);
    expect(find.text('Nuevo almacén'), findsOneWidget);
  });

  testWidgets('gerencia mira las existencias pero no las mueve', (
    WidgetTester tester,
  ) async {
    await pumpInventory(tester, role: 'Gerente');

    expect(find.byTooltip('Ver materiales'), findsOneWidget);
    expect(find.byTooltip('Registrar movimiento'), findsNothing);
    expect(find.text('Nuevo almacén'), findsNothing);
  });

  testWidgets('el ojo abre las existencias de esa bodega', (
    WidgetTester tester,
  ) async {
    final List<http.Request> requests = await pumpInventory(
      tester,
      role: 'Almacén',
    );

    await tester.tap(find.byTooltip('Ver materiales'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Almacén Central'), findsWidgets);
    expect(find.text('Cemento gris'), findsOneWidget);
    expect(find.text('40 saco'), findsOneWidget);
    expect(
      requests.map((http.Request r) => r.url.path),
      contains('/inventory/stock/w1'),
    );
  });

  testWidgets('el movimiento rellena solo el almacén de la tarjeta', (
    WidgetTester tester,
  ) async {
    final List<http.Request> requests = await pumpInventory(
      tester,
      role: 'Almacén',
    );

    await tester.tap(find.byTooltip('Registrar movimiento'));
    await tester.pumpAndSettle();

    // El almacén no se pregunta: ya se sabe cuál es.
    expect(find.text('Almacén Central'), findsWidgets);

    await tester.tap(find.text('Material'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cemento gris · saco').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Cantidad'), '2.5');
    await tester.tap(find.text('Registrar movimiento').last);
    await tester.pumpAndSettle();

    final http.Request posted = requests.lastWhere(
      (http.Request r) => r.method == 'POST',
    );
    expect(posted.url.path, '/warehouses/movements');

    final Map<String, dynamic> body =
        jsonDecode(posted.body) as Map<String, dynamic>;
    expect(body['warehouse_id'], 'w1');
    expect(body['material_id'], 'm1');
    expect(body['movement_type'], 'INPUT', reason: 'entrada por defecto');
    expect(body['quantity'], 2.5);

    await dismissToasts(tester);
  });
}
