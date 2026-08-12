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
  Map<String, dynamic> employeeJson(String id, String first, String last) =>
      <String, dynamic>{
        'id': id,
        'first_name': first,
        'last_name': last,
        'status': 'Active',
      };

  /// Abre el módulo de asistencia con sesión iniciada.
  ///
  /// Devuelve la lista de peticiones tal cual salieron, para poder mirar el
  /// cuerpo del `POST /attendance`.
  Future<List<http.Request>> pumpAttendance(
    WidgetTester tester, {
    required String role,
    bool alreadyTaken = false,
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
              if (path == '/employees') {
                return jsonResponse(<Map<String, dynamic>>[
                  employeeJson('e1', 'Ana', 'Ruiz'),
                  employeeJson('e2', 'Luis', 'Mora'),
                ]);
              }
              if (path.startsWith('/attendance/')) {
                // 404 = ese día todavía no se ha pasado lista.
                return alreadyTaken
                    ? jsonResponse(<String, dynamic>{
                        'id': 'at1',
                        'project_id': 'p1',
                        'date': '2026-08-12',
                        'logs': <Map<String, dynamic>>[
                          <String, dynamic>{
                            'employee_id': 'e1',
                            'status': 'Present',
                            'hours_worked': 8,
                          },
                        ],
                      })
                    : jsonResponse(null, status: 404);
              }
              return jsonResponse(<String, dynamic>{'id': 'at9'});
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

    container.read(routerProvider).go('/attendance');
    await tester.pumpAndSettle();
    return requests;
  }

  testWidgets('el supervisor puede pasar lista', (WidgetTester tester) async {
    await pumpAttendance(tester, role: 'Supervisor');
    expect(find.text('Pasar lista'), findsOneWidget);
  });

  testWidgets('el ingeniero consulta la lista pero no la pasa', (
    WidgetTester tester,
  ) async {
    await pumpAttendance(tester, role: 'Ingeniero');
    expect(find.text('Pasar lista'), findsNothing);
  });

  testWidgets('si el día ya tiene lista, el botón no aparece', (
    WidgetTester tester,
  ) async {
    await pumpAttendance(tester, role: 'Supervisor', alreadyTaken: true);
    expect(
      find.text('Pasar lista'),
      findsNothing,
      reason: 'la jornada se pasa una vez, no dos',
    );
  });

  testWidgets('guarda la jornada con el estado de cada trabajador', (
    WidgetTester tester,
  ) async {
    final List<http.Request> requests = await pumpAttendance(
      tester,
      role: 'Supervisor',
    );

    await tester.tap(find.text('Pasar lista'));
    await tester.pumpAndSettle();

    // La plantilla entra en la hoja, presente por defecto.
    expect(find.text('Ana Ruiz'), findsOneWidget);
    expect(find.text('Luis Mora'), findsOneWidget);

    // Ana faltó: se marca en su fila, que es la primera.
    await tester.tap(find.text('Ausente').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar lista'));
    await tester.pumpAndSettle();

    final http.Request posted = requests.lastWhere(
      (http.Request r) => r.method == 'POST' && r.url.path == '/attendance',
    );
    final Map<String, dynamic> body =
        jsonDecode(posted.body) as Map<String, dynamic>;

    expect(body['project_id'], 'p1');
    expect(
      body['date'],
      matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      reason: 'fecha simple, sin hora',
    );

    final List<Map<String, dynamic>> logs = (body['logs'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(logs.length, 2, reason: 'va toda la plantilla, no solo las faltas');
    expect(logs.first['employee_id'], 'e1');
    expect(logs.first['status'], 'Absent');
    expect(logs.first['hours_worked'], 0, reason: 'quien falta no suma horas');
    expect(logs.last['status'], 'Present');
    expect(logs.last['hours_worked'], 8);

    await dismissToasts(tester);
  });
}
