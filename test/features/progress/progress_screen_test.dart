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
  /// Abre el módulo de avance con sesión iniciada y sin parte ese día.
  Future<List<http.Request>> pumpProgress(
    WidgetTester tester, {
    required String role,
    List<Map<String, dynamic>> tasks = const <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 't1',
        'project_id': 'p1',
        'name': 'Vaciado de vigas',
        'progress': 30,
      },
    ],
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
              final String path = request.url.path;
              if (path == '/projects') {
                return jsonResponse(<Map<String, dynamic>>[projectJson()]);
              }
              if (path == '/schedule/p1') {
                return jsonResponse(tasks);
              }
              if (path.startsWith('/progress/') && request.method == 'GET') {
                // 404 = ese día no tiene parte todavía.
                return jsonResponse(null, status: 404);
              }
              return jsonResponse(<String, dynamic>{'id': 'r9'});
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

    container.read(routerProvider).go('/progress');
    await tester.pumpAndSettle();
    return requests;
  }

  testWidgets('el supervisor levanta el parte del día', (
    WidgetTester tester,
  ) async {
    await pumpProgress(tester, role: 'Supervisor');
    expect(find.text('Reporte del día'), findsOneWidget);
  });

  testWidgets('el ingeniero lo consulta pero no lo levanta', (
    WidgetTester tester,
  ) async {
    await pumpProgress(tester, role: 'Ingeniero');
    expect(find.text('Reporte del día'), findsNothing);
  });

  testWidgets('sin cronograma no hay nada que reportar', (
    WidgetTester tester,
  ) async {
    await pumpProgress(
      tester,
      role: 'Supervisor',
      tasks: const <Map<String, dynamic>>[],
    );

    await tester.tap(find.text('Reporte del día'));
    await tester.pumpAndSettle();

    expect(find.text('Sin tareas que reportar'), findsOneWidget);
  });

  testWidgets('guarda el parte con el avance de cada tarea', (
    WidgetTester tester,
  ) async {
    final List<http.Request> requests = await pumpProgress(
      tester,
      role: 'Supervisor',
    );

    await tester.tap(find.text('Reporte del día'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Clima de la jornada'),
      'Lluvia ligera',
    );

    await tester.tap(find.text('Añadir tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vaciado de vigas').last);
    await tester.pumpAndSettle();

    // La tarea entra con el avance que ya tenía, para subirlo desde ahí.
    expect(find.widgetWithText(TextFormField, '30'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Avance (%)'),
      '45.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '12.5',
    );

    await tester.tap(find.text('Guardar reporte'));
    await tester.pumpAndSettle();

    final http.Request posted = requests.lastWhere(
      (http.Request r) => r.method == 'POST',
    );
    expect(posted.url.path, '/progress/daily');

    final Map<String, dynamic> body =
        jsonDecode(posted.body) as Map<String, dynamic>;
    expect(body['project_id'], 'p1');
    expect(body['weather_condition'], 'Lluvia ligera');
    expect(
      body['report_date'],
      contains('T'),
      reason: 'el parte va en RFC 3339, no en fecha simple',
    );

    final List<Map<String, dynamic>> entries =
        (body['progress_entries'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    expect(entries.single['task_id'], 't1');
    expect(entries.single['progress_percentage'], 45.5);
    expect(entries.single['quantity_executed'], 12.5);

    await dismissToasts(tester);
  });

  testWidgets('un parte sin tareas no se manda', (WidgetTester tester) async {
    final List<http.Request> requests = await pumpProgress(
      tester,
      role: 'Supervisor',
    );

    await tester.tap(find.text('Reporte del día'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar reporte'));
    await tester.pumpAndSettle();

    expect(find.text('Añade al menos una tarea al reporte.'), findsOneWidget);
    expect(
      requests.where((http.Request r) => r.method == 'POST'),
      isEmpty,
      reason: 'se avisa en el formulario, sin gastar una petición',
    );
  });
}
