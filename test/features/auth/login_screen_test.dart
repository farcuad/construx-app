import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/core/theme/app_theme.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/auth/presentation/login_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late InMemorySecureStore store;

  setUp(() => store = InMemorySecureStore());

  /// Monta la pantalla de login con dependencias falsas.
  Future<ProviderContainer> pumpLogin(
    WidgetTester tester,
    http.Client client,
  ) async {
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
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('es'),
          supportedLocales: const <Locale>[Locale('es'), Locale('en')],
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const LoginScreen(),
        ),
      ),
    );
    // Deja resolver la lectura asíncrona de credenciales recordadas.
    await tester.pumpAndSettle();
    return container;
  }

  Finder emailField() =>
      find.widgetWithText(TextFormField, 'Correo electrónico');
  Finder passwordField() => find.widgetWithText(TextFormField, 'Contraseña');
  Finder rememberCheckbox() => find.byType(Checkbox);
  Finder submitButton() => find.text('Iniciar sesión');

  testWidgets('muestra los campos, la casilla y el botón', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    expect(emailField(), findsOneWidget);
    expect(passwordField(), findsOneWidget);
    expect(find.text('Recordar datos'), findsOneWidget);
    expect(submitButton(), findsOneWidget);
  });

  testWidgets('la casilla «Recordar datos» empieza desmarcada', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    expect(tester.widget<Checkbox>(rememberCheckbox()).value, isFalse);
  });

  testWidgets('al tocar la fila se marca y desmarca la casilla', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    await tester.tap(find.text('Recordar datos'));
    await tester.pump();
    expect(tester.widget<Checkbox>(rememberCheckbox()).value, isTrue);

    await tester.tap(find.text('Recordar datos'));
    await tester.pump();
    expect(tester.widget<Checkbox>(rememberCheckbox()).value, isFalse);
  });

  testWidgets('valida el formato del correo antes de llamar a la API', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    await pumpLogin(
      tester,
      MockClient((_) async {
        calls++;
        return jsonResponse(loginResponse());
      }),
    );

    await tester.enterText(emailField(), 'correo-invalido');
    await tester.enterText(passwordField(), 'claveSegura123');
    await tester.tap(submitButton());
    await tester.pump();

    expect(find.text('Correo electrónico inválido'), findsOneWidget);
    expect(
      calls,
      0,
      reason: 'no debe salir la petición si el email es inválido',
    );
  });

  testWidgets('valida la longitud de la contraseña', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), '123');
    await tester.tap(submitButton());
    await tester.pump();

    expect(find.text('Debe tener al menos 6 caracteres'), findsOneWidget);
  });

  testWidgets('un login correcto autentica la sesión', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await pumpLogin(
      tester,
      MockClient((_) async => jsonResponse(loginResponse())),
    );

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), 'claveSegura123');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.authenticated,
    );
    await dismissToasts(tester);
  });

  testWidgets('con «Recordar datos» marcado guarda las credenciales cifradas', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      MockClient((_) async => jsonResponse(loginResponse())),
    );

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), 'claveSegura123');
    await tester.tap(find.text('Recordar datos'));
    await tester.pump();
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(store.snapshot[StorageKeys.rememberMe], '1');
    expect(store.snapshot[StorageKeys.rememberedEmail], 'andres@xyz.com');
    expect(store.snapshot[StorageKeys.rememberedPassword], 'claveSegura123');
    await dismissToasts(tester);
  });

  testWidgets('sin «Recordar datos» no guarda credenciales', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      MockClient((_) async => jsonResponse(loginResponse())),
    );

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), 'claveSegura123');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(store.snapshot.containsKey(StorageKeys.rememberedPassword), isFalse);
    await dismissToasts(tester);
  });

  testWidgets('prerrellena el formulario con las credenciales recordadas', (
    WidgetTester tester,
  ) async {
    store = InMemorySecureStore(<String, String>{
      StorageKeys.rememberMe: '1',
      StorageKeys.rememberedEmail: 'maria@xyz.com',
      StorageKeys.rememberedPassword: 'claveGuardada',
    });

    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    expect(find.text('maria@xyz.com'), findsOneWidget);
    expect(tester.widget<Checkbox>(rememberCheckbox()).value, isTrue);
  });

  testWidgets('muestra el mensaje de error del backend', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      MockClient(
        (_) async => jsonResponse(<String, String>{
          'message': 'Credenciales Incorrectas',
        }, status: 401),
      ),
    );

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), 'claveIncorrecta');
    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(find.text('Credenciales Incorrectas'), findsOneWidget);
  });

  testWidgets('la contraseña se oculta y se puede revelar', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, MockClient((_) async => jsonResponse(null)));

    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('no se envía dos veces si se pulsa repetidamente', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    await pumpLogin(
      tester,
      MockClient((_) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return jsonResponse(loginResponse());
      }),
    );

    await tester.enterText(emailField(), 'andres@xyz.com');
    await tester.enterText(passwordField(), 'claveSegura123');
    await tester.tap(submitButton());
    await tester.pump();
    // Con la petición en vuelo el botón muestra el spinner y no acepta taps.
    await tester.tap(
      find.byType(CircularProgressIndicator),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    await dismissToasts(tester);
  });
}
