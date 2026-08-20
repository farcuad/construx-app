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
import 'package:mi_app_constructora/features/home/presentation/home_screen.dart';
import 'package:mi_app_constructora/features/subscriptions/presentation/subscription_screen.dart';

import '../../helpers/test_helpers.dart';

void main() {
  Future<InMemorySecureStore> storedSession() async {
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
    return store;
  }

  Future<void> pumpWithSubscription(
    WidgetTester tester,
    Map<String, dynamic> subscription,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final InMemorySecureStore store = await storedSession();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        secureStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWith(
          (Ref ref) => ApiClient(
            baseUrl: 'https://api.test',
            tokenProvider: () => ref.read(authTokenProvider),
            httpClient: MockClient((http.Request request) async {
              if (request.url.path == '/subscriptions/me') {
                return jsonResponse(subscription);
              }
              return jsonResponse(null);
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
  }

  Map<String, dynamic> subscription({
    required String status,
    String? trialEndDate,
  }) => <String, dynamic>{
    'id': '874b5791-5d41-43a0-bbd6-804c51267903',
    'company_id': '13ad2348-3f8e-4d64-9e9e-f185f7e42c9b',
    'status': status,
    'start_date': '2026-08-05T19:01:01Z',
    'trial_end_date': trialEndDate,
    'price': 0,
    'billing_cycle': 'monthly',
    'max_projects': 1,
    'max_users': 3,
    'max_storage_mb': 100,
    'features': <String, dynamic>{},
  };

  testWidgets('un trial vencido bloquea los módulos y muestra el plan', (
    WidgetTester tester,
  ) async {
    await pumpWithSubscription(
      tester,
      subscription(status: 'trial', trialEndDate: '2020-08-19T19:01:01Z'),
    );

    expect(find.byType(SubscriptionScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('El acceso de tu empresa venció'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('100 MB'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('un trial vigente continúa al panel', (
    WidgetTester tester,
  ) async {
    await pumpWithSubscription(
      tester,
      subscription(status: 'trial', trialEndDate: '2099-08-19T19:01:01Z'),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(SubscriptionScreen), findsNothing);
  });
}
