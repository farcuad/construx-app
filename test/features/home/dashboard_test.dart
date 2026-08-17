import 'package:fl_chart/fl_chart.dart';
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

import '../../helpers/test_helpers.dart';

void main() {
  /// Arranca la app con sesión iniciada y el panel ya cargado.
  ///
  /// [handler] responde a las peticiones del panel: `GET /projects` y
  /// `GET /dashboard/financial/{project_id}`.
  Future<List<Uri>> pumpDashboard(
    WidgetTester tester, {
    required http.Response Function(Uri url) handler,
    String role = 'Administrador',
    Size size = const Size(1000, 1800),
  }) async {
    tester.view.physicalSize = size;
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

    final List<Uri> requested = <Uri>[];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            httpClient: MockClient((http.Request request) async {
              requested.add(request.url);
              return handler(request.url);
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
    return requested;
  }

  /// Responde con un proyecto y sus KPIs.
  http.Response Function(Uri) singleProject({
    Map<String, dynamic>? kpis,
    Map<String, dynamic>? project,
  }) => (Uri url) {
    if (url.path == '/projects') {
      return jsonResponse(<Map<String, dynamic>>[project ?? projectJson()]);
    }
    if (url.path.startsWith('/dashboard/financial/')) {
      return jsonResponse(kpis ?? kpisJson());
    }
    return jsonResponse(null);
  };

  testWidgets('el panel muestra las cuatro tarjetas clave del dashboard', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester, handler: singleProject());

    expect(find.text('Presupuesto total'), findsOneWidget);
    expect(find.text('Total gastado'), findsOneWidget);
    expect(find.text('Cobrado vs. facturado'), findsOneWidget);
    expect(find.text('Variación financiera'), findsOneWidget);

    // La leyenda de la tendencia reutiliza las etiquetas de las series.
    expect(find.text('Facturado'), findsOneWidget);
    expect(find.text('Cobrado'), findsOneWidget);
    expect(
      find.text('Gastos'),
      findsWidgets,
      reason: 'la leyenda de la tendencia y la pestaña de gastos se llaman igual',
    );

    // Y el proyecto al que pertenecen.
    expect(find.text('Torres del Parque'), findsOneWidget);
  });

  testWidgets('pide los KPIs del proyecto seleccionado', (
    WidgetTester tester,
  ) async {
    final List<Uri> requested = await pumpDashboard(
      tester,
      handler: singleProject(),
    );

    expect(
      requested.map((Uri u) => u.path),
      contains('/dashboard/financial/p1'),
    );
  });

  testWidgets('calcula el consumo del presupuesto (gastos + compras)', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester, handler: singleProject());

    // 980.000 + 620.000 = 1.600.000 sobre 2.500.000 → 64 %.
    expect(find.text('Presupuesto consumido'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
  });

  testWidgets('avisa cuando lo comprometido supera el presupuesto', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(
      tester,
      handler: singleProject(
        kpis: kpisJson(
          totalBudget: 1000000,
          totalExpenses: 800000,
          totalPurchased: 400000,
        ),
      ),
    );

    expect(find.textContaining('Sobrepasa el presupuesto'), findsOneWidget);
  });

  testWidgets('al cambiar de proyecto pide los KPIs del nuevo', (
    WidgetTester tester,
  ) async {
    final List<Uri> requested = await pumpDashboard(
      tester,
      handler: (Uri url) {
        if (url.path == '/projects') {
          return jsonResponse(<Map<String, dynamic>>[
            projectJson(),
            projectJson(id: 'p2', name: 'Centro Comercial Norte'),
          ]);
        }
        if (url.path == '/dashboard/financial/p1') {
          return jsonResponse(kpisJson());
        }
        if (url.path == '/dashboard/financial/p2') {
          return jsonResponse(kpisJson(projectId: 'p2', totalBudget: 999));
        }
        return jsonResponse(null);
      },
    );

    // Arranca en el primer proyecto de la lista.
    expect(find.text('Torres del Parque'), findsOneWidget);

    await tester.tap(find.text('Torres del Parque'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centro Comercial Norte').last);
    await tester.pumpAndSettle();

    expect(find.text('Centro Comercial Norte'), findsOneWidget);
    expect(
      requested.map((Uri u) => u.path),
      contains('/dashboard/financial/p2'),
    );
  });

  testWidgets('sin proyectos invita a crear el primero', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(tester, handler: (_) => jsonResponse(null));

    expect(find.text('Aún no hay proyectos'), findsOneWidget);
    expect(find.text('Ir a proyectos'), findsOneWidget);
  });

  testWidgets('sin permiso dashboard:read no pide los indicadores', (
    WidgetTester tester,
  ) async {
    final List<Uri> requested = await pumpDashboard(
      tester,
      role: 'Supervisor',
      handler: singleProject(),
    );

    expect(find.text('Sin acceso al tablero'), findsOneWidget);
    expect(
      requested
          .map((Uri u) => u.path)
          .where((String p) => p.startsWith('/dashboard/')),
      isEmpty,
      reason: 'no tiene sentido gastar una petición que dará 403',
    );
  });

  testWidgets('dibuja la tendencia mensual y la dona de categorías', (
    WidgetTester tester,
  ) async {
    // Pantalla alta de propósito: los dos gráficos quedan bajo las tarjetas.
    await pumpDashboard(
      tester,
      size: const Size(1100, 2800),
      handler: singleProject(),
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Tendencia financiera'), findsOneWidget);
    expect(find.text('Gastos por categoría'), findsOneWidget);

    // Leyenda de la dona con los rubros del desglose.
    for (final String category in <String>['Materiales', 'Personal', 'Equipos']) {
      expect(find.text(category), findsOneWidget);
    }
  });

  testWidgets('sin categorías cae a la distribución por defecto', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(
      tester,
      size: const Size(1100, 2800),
      handler: singleProject(
        kpis: kpisJson(expensesByCategory: const <Map<String, dynamic>>[]),
      ),
    );

    expect(find.byType(PieChart), findsOneWidget);
    for (final String category in <String>['Materiales', 'Personal', 'Equipos']) {
      expect(find.text(category), findsOneWidget);
    }
  });

  testWidgets('sin tendencia muestra el estado vacío del gráfico', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(
      tester,
      size: const Size(1100, 2800),
      handler: singleProject(
        kpis: kpisJson(monthlyTrends: const <Map<String, dynamic>>[]),
      ),
    );

    expect(find.text('Sin datos de tendencia para este proyecto.'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('sin gastos la dona avisa en vez de pintar vacío', (
    WidgetTester tester,
  ) async {
    await pumpDashboard(
      tester,
      size: const Size(1100, 2800),
      handler: singleProject(
        kpis: kpisJson(
          totalExpenses: 0,
          totalPurchased: 0,
          expensesByCategory: const <Map<String, dynamic>>[],
        ),
      ),
    );

    expect(find.text('Sin gastos registrados.'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });
}