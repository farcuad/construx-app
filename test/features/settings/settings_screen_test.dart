import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:mi_app_constructora/app.dart';
import 'package:mi_app_constructora/core/i18n/app_language.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/providers.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/application/auth_controller.dart';
import 'package:mi_app_constructora/features/auth/presentation/login_screen.dart';
import 'package:mi_app_constructora/features/expenses/presentation/expenses_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';
import 'package:mi_app_constructora/features/home/presentation/widgets/app_nav_bar.dart';
import 'package:mi_app_constructora/features/projects/presentation/projects_screen.dart';
import 'package:mi_app_constructora/features/settings/presentation/settings_screen.dart';
import 'package:mi_app_constructora/features/settings/presentation/terms_screen.dart';

import '../../helpers/test_helpers.dart';

/// Pruebas de la barra inferior fija y de la pantalla de ajustes.
void main() {
  /// Arranca la app con sesión iniciada en el panel y devuelve el almacén,
  /// para poder comprobar qué se recordó.
  Future<InMemorySecureStore> pumpApp(
    WidgetTester tester, {
    String role = 'Administrador',
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

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
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
    return store;
  }

  /// Toca una pestaña de la barra inferior por su rótulo.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(of: find.byType(AppNavBar), matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  group('barra inferior', () {
    testWidgets('un administrador ve las cuatro pestañas', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      for (final String label in <String>[
        'Panel',
        'Proyectos',
        'Gastos',
        'Ajustes',
      ]) {
        expect(
          find.descendant(
            of: find.byType(AppNavBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: '«$label» debería estar siempre a la vista',
        );
      }
    });

    testWidgets('lleva de una vista a otra y sigue estando allí', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await tapTab(tester, 'Gastos');
      expect(find.byType(ExpensesScreen), findsOneWidget);
      expect(find.byType(AppNavBar), findsOneWidget);

      await tapTab(tester, 'Proyectos');
      expect(find.byType(ProjectsScreen), findsOneWidget);
      expect(find.byType(AppNavBar), findsOneWidget);

      await tapTab(tester, 'Panel');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppNavBar), findsOneWidget);
    });

    testWidgets('un rol sin gastos no ve esa pestaña', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, role: 'Supervisor');

      final Finder bar = find.byType(AppNavBar);
      expect(
        find.descendant(of: bar, matching: find.text('Proyectos')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Gastos')),
        findsNothing,
        reason: 'una pestaña que devolvería 403 es peor que no tenerla',
      );
      // Ajustes no pide permiso: ahí está el cierre de sesión.
      expect(
        find.descendant(of: bar, matching: find.text('Ajustes')),
        findsOneWidget,
      );
    });
  });

  group('ajustes', () {
    testWidgets('reúne sesión, idioma y términos', (WidgetTester tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Ajustes');

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('andres@xyz.com'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Términos y condiciones'), findsOneWidget);
      for (final AppLanguage language in AppLanguage.values) {
        expect(find.text(language.label), findsOneWidget);
      }
    });

    testWidgets('los términos se abren y se vuelve a ajustes', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Ajustes');

      await tester.tap(find.text('Términos y condiciones'));
      await tester.pumpAndSettle();
      expect(find.byType(TermsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('cerrar sesión devuelve al login', (WidgetTester tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Ajustes');

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('idioma', () {
    testWidgets('cambiarlo traduce el armazón de la app', (
      WidgetTester tester,
    ) async {
      final InMemorySecureStore store = await pumpApp(tester);
      await tapTab(tester, 'Ajustes');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      final Finder bar = find.byType(AppNavBar);
      expect(
        find.descendant(of: bar, matching: find.text('Dashboard')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: find.text('Settings')),
        findsOneWidget,
      );
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Terms and conditions'), findsOneWidget);
      expect(
        store.snapshot[StorageKeys.language],
        'en',
        reason: 'la elección debe sobrevivir al siguiente arranque',
      );
    });

    testWidgets('el portugués también llega al menú lateral', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Ajustes');

      await tester.tap(find.text('Português'));
      await tester.pumpAndSettle();

      // La barra pone el botón del cajón con el rótulo del idioma del sistema,
      // así que se busca por el icono y no por el texto.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Despesas'), findsWidgets);
      expect(find.text('Fornecedores'), findsOneWidget);
    });

    testWidgets('el idioma también llega dentro de un módulo', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Ajustes');
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tapTab(tester, 'Expenses');

      // Título de la barra y el estado vacío del módulo, que sale del
      // selector de obra compartido.
      expect(find.text('Expenses'), findsWidgets);
      expect(find.text('No projects yet'), findsOneWidget);
      expect(
        find.text('Expenses are charged to a site. Create the first one.'),
        findsOneWidget,
      );
    });

    testWidgets('se recuerda entre arranques', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final InMemorySecureStore store = InMemorySecureStore(<String, String>{
        StorageKeys.language: 'en',
      });
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

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          secureStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWith(
            (Ref ref) => ApiClient(
              baseUrl: 'https://api.test',
              tokenProvider: () => ref.read(authTokenProvider),
              httpClient: MockClient(
                (_) async => jsonResponse(const <Object>[]),
              ),
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

      expect(
        find.descendant(
          of: find.byType(AppNavBar),
          matching: find.text('Dashboard'),
        ),
        findsOneWidget,
      );
    });
  });
}
