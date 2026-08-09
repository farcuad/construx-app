import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/api_exception.dart';

import '../helpers/test_helpers.dart';

void main() {
  const String baseUrl = 'https://api.test';

  group('ApiClient · construcción de la petición', () {
    test('compone la URL sin prefijo /api y sin barra duplicada', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: '$baseUrl/',
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.getObject('/projects');

      expect(requests.single.url.toString(), '$baseUrl/projects');
    });

    test('acepta rutas sin barra inicial', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.getObject('clients');

      expect(requests.single.url.path, '/clients');
    });

    test('serializa los query params y descarta los nulos', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.getObject(
        '/attendance/p1',
        query: <String, dynamic>{'date': '2026-08-08', 'extra': null},
      );

      expect(requests.single.url.queryParameters, <String, String>{
        'date': '2026-08-08',
      });
    });

    test('adjunta el Bearer token cuando la petición es autenticada', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        tokenProvider: () => 'token-123',
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.getObject('/projects');

      expect(requests.single.headers['authorization'], 'Bearer token-123');
    });

    test('omite el header Authorization en rutas públicas', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        tokenProvider: () => 'token-123',
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.post('/login', authenticated: false, body: <String, String>{});

      expect(requests.single.headers.containsKey('authorization'), isFalse);
    });

    test('envía el cuerpo como JSON', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: recordingClient(
          requests,
          (_) => jsonResponse(<String, dynamic>{'ok': true}),
        ),
      );

      await api.post(
        '/clients',
        body: <String, dynamic>{'name': 'Cliente Ñandú'},
      );

      final RecordedRequest request = requests.single;
      expect(request.method, 'POST');
      expect(request.json['name'], 'Cliente Ñandú');
      expect(request.headers['content-type'], contains('application/json'));
    });
  });

  group('ApiClient · respuestas', () {
    test('decodifica una lista JSON', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient(
          (_) async => jsonResponse(<Map<String, dynamic>>[
            <String, dynamic>{'id': '1'},
            <String, dynamic>{'id': '2'},
          ]),
        ),
      );

      expect(await api.getList('/projects'), hasLength(2));
    });

    test('convierte un cuerpo `null` en lista vacía', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((_) async => jsonResponse(null)),
      );

      expect(await api.getList('/projects'), isEmpty);
    });

    test('acepta 204 sin cuerpo en DELETE', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((_) async => http.Response('', 204)),
      );

      await expectLater(api.delete('/positions/1'), completes);
    });

    test('decodifica UTF-8 aunque falte el charset en el content-type', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(jsonEncode(<String, dynamic>{'name': 'Bogotá D.C.'})),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          ),
        ),
      );

      final Map<String, dynamic> body = await api.getObject('/projects/1');
      expect(body['name'], 'Bogotá D.C.');
    });
  });

  group('ApiClient · errores', () {
    Future<void> expectError<T extends ApiException>(
      int status,
      String body, {
      required String expectedMessage,
    }) async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((_) async => textResponse(body, status: status)),
      );

      await expectLater(
        api.getObject('/projects'),
        throwsA(
          isA<T>().having(
            (T e) => e.message,
            'message',
            expectedMessage,
          ),
        ),
      );
    }

    test('401 con cuerpo JSON usa el campo message', () async {
      await expectError<UnauthorizedException>(
        401,
        jsonEncode(<String, String>{'message': 'Credenciales Incorrectas'}),
        expectedMessage: 'Credenciales Incorrectas',
      );
    });

    test('403 con texto plano usa el texto tal cual', () async {
      await expectError<ForbiddenException>(
        403,
        'Acceso denegado: solo el administrador del sistema\n',
        expectedMessage: 'Acceso denegado: solo el administrador del sistema',
      );
    });

    test('402 mapea a suscripción requerida', () async {
      await expectError<SubscriptionRequiredException>(
        402,
        'Suscripción inactiva o expirada',
        expectedMessage: 'Suscripción inactiva o expirada',
      );
    });

    test('409 mapea a conflicto', () async {
      await expectError<ConflictException>(
        409,
        '',
        expectedMessage: 'La operación entra en conflicto con datos existentes.',
      );
    });

    test('404 mapea a no encontrado', () async {
      await expectError<NotFoundException>(
        404,
        'no encontrado',
        expectedMessage: 'no encontrado',
      );
    });

    test('500 mapea a error de servidor con mensaje por defecto', () async {
      await expectError<ServerException>(
        500,
        '',
        expectedMessage: 'Error del servidor (500). Inténtalo más tarde.',
      );
    });

    test('un fallo de red se convierte en NetworkException', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient(
          (_) async => throw http.ClientException('conexión rechazada'),
        ),
      );

      await expectLater(
        api.getObject('/projects'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('el timeout se convierte en NetworkException', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        timeout: const Duration(milliseconds: 30),
        httpClient: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return jsonResponse(<String, dynamic>{});
        }),
      );

      await expectLater(
        api.getObject('/projects'),
        throwsA(
          isA<NetworkException>().having(
            (NetworkException e) => e.message,
            'message',
            contains('tardó demasiado'),
          ),
        ),
      );
    });

    test('un JSON malformado en un 200 lanza ParseException', () async {
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((_) async => http.Response('no-es-json{', 200)),
      );

      await expectLater(
        api.getObject('/projects'),
        throwsA(isA<ParseException>()),
      );
    });

    test('un 401 autenticado dispara onUnauthorized una sola vez', () async {
      int calls = 0;
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        tokenProvider: () => 'token-expirado',
        onUnauthorized: () => calls++,
        httpClient: MockClient(
          (_) async => http.Response('Token inválido o expirado', 401),
        ),
      );

      await expectLater(
        api.getObject('/projects'),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(calls, 1);
    });

    test('un 401 en ruta pública no dispara onUnauthorized', () async {
      int calls = 0;
      final ApiClient api = ApiClient(
        baseUrl: baseUrl,
        onUnauthorized: () => calls++,
        httpClient: MockClient(
          (_) async => jsonResponse(
            <String, String>{'message': 'Credenciales Incorrectas'},
            status: 401,
          ),
        ),
      );

      await expectLater(
        api.post('/login', authenticated: false, body: <String, String>{}),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(calls, 0, reason: 'el login fallido no es una sesión expirada');
    });
  });
}
