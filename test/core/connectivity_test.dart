import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/connectivity.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/core/widgets/offline_gate.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/widgets/app_nav_bar.dart';
import 'package:mi_app_constructora/features/settings/presentation/settings_screen.dart';

import '../helpers/test_helpers.dart';

/// Sonda de red gobernada por el test.
class _FakeProbe implements ConnectivityProbe {
  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onlineChanges => controller.stream;
}

/// Pruebas del aviso de «sin conexión».
void main() {
  /// Arranca la app con sesión iniciada y la sonda bajo control.
  Future<_FakeProbe> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _FakeProbe probe = _FakeProbe();
    addTearDown(probe.controller.close);

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

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        connectivityProbeProvider.overrideWithValue(probe),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            tokenProvider: () => ref.read(authTokenProvider),
            httpClient: MockClient((_) async => jsonResponse(const <Object>[])),
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
    return probe;
  }

  testWidgets('mientras no se sabe nada de la red, la app se usa normal', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    expect(
      find.byType(OfflineView),
      findsNothing,
      reason: 'tapar la pantalla en cada arranque sería peor que el problema',
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('al caerse la red aparece el aviso a pantalla completa', (
    WidgetTester tester,
  ) async {
    final _FakeProbe probe = await pumpApp(tester);

    probe.controller.add(false);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineView), findsOneWidget);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
  });

  testWidgets('el aviso tapa la app pero no la desmonta', (
    WidgetTester tester,
  ) async {
    final _FakeProbe probe = await pumpApp(tester);

    // Se navega a Ajustes y ahí se cae la red.
    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    probe.controller.add(false);
    await tester.pumpAndSettle();
    expect(find.byType(OfflineView), findsOneWidget);
    expect(
      find.byType(SettingsScreen),
      findsOneWidget,
      reason: 'la pantalla sigue debajo, solo está tapada',
    );

    // Al volver la señal se sigue donde se estaba, sin pasar por el panel.
    probe.controller.add(true);
    await tester.pumpAndSettle();
    expect(find.byType(OfflineView), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('el aviso también habla el idioma elegido', (
    WidgetTester tester,
  ) async {
    final _FakeProbe probe = await pumpApp(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    probe.controller.add(false);
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão'), findsOneWidget);
  });

  test('sin lectura de red todavía, no se da por caída', () {
    final _FakeProbe probe = _FakeProbe();
    addTearDown(probe.controller.close);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        connectivityProbeProvider.overrideWithValue(probe),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(isOfflineProvider), isFalse);
  });
}
