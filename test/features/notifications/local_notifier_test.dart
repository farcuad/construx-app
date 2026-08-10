import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/home/presentation/widgets/app_nav_bar.dart';
import 'package:mi_app_constructora/features/notifications/application/notifications_providers.dart';
import 'package:mi_app_constructora/features/notifications/data/local_notifier.dart';
import 'package:mi_app_constructora/features/notifications/domain/notification_models.dart';

import '../../helpers/test_helpers.dart';

/// Notificador de mentira: apunta lo que se le pide en vez de tocar Android.
class _RecordingNotifier implements LocalNotifier {
  final List<AppNotification> shown = <AppNotification>[];
  final List<NotificationChannelText> channels = <NotificationChannelText>[];
  bool initialized = false;

  @override
  Future<void> initialize({required ValueChanged<String?> onOpened}) async {
    initialized = true;
  }

  @override
  Future<void> show(
    AppNotification notification,
    NotificationChannelText text,
  ) async {
    shown.add(notification);
    channels.add(text);
  }
}

/// Pruebas del paso de aviso del socket a notificación del teléfono.
void main() {
  /// Arranca la app con el socket y el notificador bajo control.
  Future<(_RecordingNotifier, StreamController<AppNotification>)> pumpApp(
    WidgetTester tester, {
    List<String> permissions = const <String>['*'],
  }) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _RecordingNotifier notifier = _RecordingNotifier();
    final StreamController<AppNotification> socket =
        StreamController<AppNotification>.broadcast();
    addTearDown(socket.close);

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

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        localNotifierProvider.overrideWithValue(notifier),
        notificationsStreamProvider.overrideWith(
          (Ref ref) => socket.stream,
        ),
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
    return (notifier, socket);
  }

  const AppNotification aviso = AppNotification(
    id: 'n1',
    title: 'Orden de compra pendiente',
    message: 'Requiere tu aprobación',
    priority: NotificationPriority.high,
  );

  testWidgets('se pide el permiso del sistema al arrancar la sesión', (
    WidgetTester tester,
  ) async {
    final (_RecordingNotifier notifier, _) = await pumpApp(tester);

    expect(notifier.initialized, isTrue);
  });

  testWidgets('un aviso del socket sale a la bandeja del teléfono', (
    WidgetTester tester,
  ) async {
    final (
      _RecordingNotifier notifier,
      StreamController<AppNotification> socket,
    ) = await pumpApp(tester);

    socket.add(aviso);
    await tester.pumpAndSettle();

    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.title, 'Orden de compra pendiente');
    expect(notifier.shown.single.message, 'Requiere tu aprobación');
  });

  testWidgets('el aviso llega estando en cualquier pantalla', (
    WidgetTester tester,
  ) async {
    final (
      _RecordingNotifier notifier,
      StreamController<AppNotification> socket,
    ) = await pumpApp(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();

    socket.add(aviso);
    await tester.pumpAndSettle();

    expect(
      notifier.shown,
      hasLength(1),
      reason: 'el socket vive por encima del router, no de la campana',
    );
  });

  testWidgets('el canal del sistema se nombra en el idioma activo', (
    WidgetTester tester,
  ) async {
    final (
      _RecordingNotifier notifier,
      StreamController<AppNotification> socket,
    ) = await pumpApp(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(AppNavBar),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    socket.add(aviso);
    await tester.pumpAndSettle();

    expect(notifier.channels.single.name, 'Site alerts');
  });

  testWidgets('sin permiso de avisos no se notifica nada', (
    WidgetTester tester,
  ) async {
    final (
      _RecordingNotifier notifier,
      StreamController<AppNotification> socket,
    ) = await pumpApp(tester, permissions: const <String>['dashboard:read']);

    socket.add(aviso);
    await tester.pumpAndSettle();

    expect(
      notifier.shown,
      isEmpty,
      reason: 'ni siquiera se abre el socket para ese rol',
    );
  });

  test('el id de Android es estable y cabe en un entero de Java', () {
    final int first = SystemLocalNotifier.notificationId('n1');

    expect(
      SystemLocalNotifier.notificationId('n1'),
      first,
      reason: 'el mismo aviso dos veces no debe duplicar la notificación',
    );
    expect(first, isNonNegative);
    expect(first, lessThanOrEqualTo(0x7fffffff));
    expect(SystemLocalNotifier.notificationId('n2'), isNot(first));
  });
}
