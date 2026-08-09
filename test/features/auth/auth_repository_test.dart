import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/api_exception.dart';
import 'package:mi_app_constructora/core/storage/secure_store.dart';
import 'package:mi_app_constructora/features/auth/data/auth_repository.dart';
import 'package:mi_app_constructora/features/auth/domain/session.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late InMemorySecureStore store;

  AuthRepository buildRepository(http.Client client) => AuthRepository(
    ApiClient(baseUrl: 'https://api.test', httpClient: client),
    store,
  );

  setUp(() => store = InMemorySecureStore());

  group('login', () {
    test('devuelve la sesión y la persiste cifrada', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final AuthRepository repository = buildRepository(
        recordingClient(requests, (_) => jsonResponse(loginResponse())),
      );

      final Session session = await repository.login(
        email: 'andres@xyz.com',
        password: 'claveSegura123',
      );

      expect(session.user.email, 'andres@xyz.com');
      expect(session.user.isAdmin, isTrue);
      expect(requests.single.url.path, '/login');
      expect(requests.single.json, <String, String>{
        'email': 'andres@xyz.com',
        'password': 'claveSegura123',
      });
      expect(store.snapshot[StorageKeys.token], session.token);
      expect(
        jsonDecode(store.snapshot[StorageKeys.user]!),
        containsPair('email', 'andres@xyz.com'),
      );
    });

    test('con rememberMe guarda las credenciales', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(loginResponse())),
      );

      await repository.login(
        email: 'andres@xyz.com',
        password: 'claveSegura123',
        rememberMe: true,
      );

      expect(store.snapshot[StorageKeys.rememberMe], '1');
      expect(store.snapshot[StorageKeys.rememberedEmail], 'andres@xyz.com');
      expect(
        store.snapshot[StorageKeys.rememberedPassword],
        'claveSegura123',
      );
    });

    test('sin rememberMe borra credenciales guardadas antes', () async {
      await store.write(StorageKeys.rememberMe, '1');
      await store.write(StorageKeys.rememberedEmail, 'viejo@xyz.com');
      await store.write(StorageKeys.rememberedPassword, 'viejaClave');

      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(loginResponse())),
      );

      await repository.login(
        email: 'andres@xyz.com',
        password: 'claveSegura123',
      );

      expect(store.snapshot.containsKey(StorageKeys.rememberMe), isFalse);
      expect(
        store.snapshot.containsKey(StorageKeys.rememberedPassword),
        isFalse,
      );
    });

    test('propaga UnauthorizedException con credenciales incorrectas', () async {
      final AuthRepository repository = buildRepository(
        MockClient(
          (_) async => jsonResponse(
            <String, String>{'message': 'Credenciales Incorrectas'},
            status: 401,
          ),
        ),
      );

      await expectLater(
        repository.login(email: 'a@b.com', password: 'mala'),
        throwsA(
          isA<UnauthorizedException>().having(
            (UnauthorizedException e) => e.message,
            'message',
            'Credenciales Incorrectas',
          ),
        ),
      );
      expect(store.snapshot, isEmpty, reason: 'no debe persistir nada');
    });

    test('lanza ParseSessionException si falta el token', () async {
      final AuthRepository repository = buildRepository(
        MockClient(
          (_) async => jsonResponse(<String, dynamic>{
            'message': 'ok',
            'user': <String, dynamic>{'id': '1'},
          }),
        ),
      );

      await expectLater(
        repository.login(email: 'a@b.com', password: 'x'),
        throwsA(isA<ParseSessionException>()),
      );
    });
  });

  group('restoreSession', () {
    test('devuelve null cuando no hay nada guardado', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );
      expect(await repository.restoreSession(), isNull);
    });

    test('restaura una sesión vigente', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(loginResponse())),
      );
      await repository.login(email: 'andres@xyz.com', password: 'x');

      final Session? restored = await repository.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.user.email, 'andres@xyz.com');
      expect(restored.user.isAdmin, isTrue);
    });

    test('descarta y limpia una sesión con el token expirado', () async {
      final String expired = fakeJwt(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      await store.write(StorageKeys.token, expired);
      await store.write(
        StorageKeys.user,
        jsonEncode(<String, dynamic>{
          'id': '1',
          'name': 'Andrés',
          'email': 'a@b.com',
          'role': 'Administrador',
          'permissions': <String>['*'],
        }),
      );

      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );

      expect(await repository.restoreSession(), isNull);
      expect(store.snapshot.containsKey(StorageKeys.token), isFalse);
    });

    test('descarta un usuario corrupto y limpia la sesión', () async {
      await store.write(StorageKeys.token, fakeJwt());
      await store.write(StorageKeys.user, 'esto-no-es-json');

      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );

      expect(await repository.restoreSession(), isNull);
      expect(store.snapshot.containsKey(StorageKeys.token), isFalse);
    });
  });

  group('credenciales recordadas', () {
    test('devuelve null si el flag está desactivado', () async {
      await store.write(StorageKeys.rememberedEmail, 'a@b.com');
      await store.write(StorageKeys.rememberedPassword, 'clave');

      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );

      expect(await repository.rememberedCredentials(), isNull);
    });

    test('devuelve las credenciales cuando el flag está activo', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );
      await repository.setRememberedCredentials(
        const RememberedCredentials(email: 'a@b.com', password: 'clave'),
      );

      final RememberedCredentials? saved =
          await repository.rememberedCredentials();

      expect(saved?.email, 'a@b.com');
      expect(saved?.password, 'clave');
    });

    test('devuelve null si los datos están incompletos', () async {
      await store.write(StorageKeys.rememberMe, '1');
      await store.write(StorageKeys.rememberedEmail, 'a@b.com');

      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(null)),
      );

      expect(await repository.rememberedCredentials(), isNull);
    });
  });

  group('clearSession', () {
    test('borra la sesión pero conserva lo recordado', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(loginResponse())),
      );
      await repository.login(
        email: 'andres@xyz.com',
        password: 'clave',
        rememberMe: true,
      );

      await repository.clearSession();

      expect(store.snapshot.containsKey(StorageKeys.token), isFalse);
      expect(store.snapshot.containsKey(StorageKeys.user), isFalse);
      expect(store.snapshot[StorageKeys.rememberedEmail], 'andres@xyz.com');
    });

    test('forgetEverything borra también lo recordado', () async {
      final AuthRepository repository = buildRepository(
        MockClient((_) async => jsonResponse(loginResponse())),
      );
      await repository.login(
        email: 'andres@xyz.com',
        password: 'clave',
        rememberMe: true,
      );

      await repository.forgetEverything();

      expect(store.snapshot, isEmpty);
    });
  });
}
