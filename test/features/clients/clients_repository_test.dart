import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/api_exception.dart';
import 'package:mi_app_constructora/features/clients/data/clients_repository.dart';
import 'package:mi_app_constructora/features/clients/domain/client.dart';

import '../../helpers/test_helpers.dart';

void main() {
  ClientsRepository buildRepository(http.Client client) =>
      ClientsRepository(ApiClient(baseUrl: 'https://api.test', httpClient: client));

  Map<String, dynamic> clientJson() => <String, dynamic>{
    'id': 'cli-1',
    'company_id': 'c1',
    'name': 'Inversiones Andinas S.A.S.',
    'nit': '901123456-7',
    'address': 'Cra 7 #45-10',
    'phone': '3001234567',
    'email': 'contacto@andinas.co',
    'is_active': true,
    'created_at': '2026-08-01T10:00:00Z',
  };

  test('fetchAll mapea la lista de /clients', () async {
    final List<RecordedRequest> requests = <RecordedRequest>[];
    final ClientsRepository repository = buildRepository(
      recordingClient(
        requests,
        (_) => jsonResponse(<Map<String, dynamic>>[clientJson()]),
      ),
    );

    final List<Client> clients = await repository.fetchAll();

    expect(requests.single.url.path, '/clients');
    expect(clients.single.name, 'Inversiones Andinas S.A.S.');
    expect(clients.single.nit, '901123456-7');
    expect(clients.single.isActive, isTrue);
  });

  test('create envía todos los campos del cliente', () async {
    final List<RecordedRequest> requests = <RecordedRequest>[];
    final ClientsRepository repository = buildRepository(
      recordingClient(requests, (_) => jsonResponse(clientJson(), status: 201)),
    );

    await repository.create(
      const Client(
        id: '',
        name: 'Inversiones Andinas S.A.S.',
        nit: '901123456-7',
        address: 'Cra 7 #45-10',
        phone: '3001234567',
        email: 'contacto@andinas.co',
      ),
    );

    final RecordedRequest request = requests.single;
    expect(request.method, 'POST');
    expect(request.json, <String, dynamic>{
      'name': 'Inversiones Andinas S.A.S.',
      'nit': '901123456-7',
      'address': 'Cra 7 #45-10',
      'phone': '3001234567',
      'email': 'contacto@andinas.co',
    });
  });

  test('update apunta a /clients/{id} con PUT', () async {
    final List<RecordedRequest> requests = <RecordedRequest>[];
    final ClientsRepository repository = buildRepository(
      recordingClient(requests, (_) => jsonResponse(clientJson())),
    );

    await repository.update(const Client(id: 'cli-1', name: 'Nuevo nombre'));

    expect(requests.single.method, 'PUT');
    expect(requests.single.url.path, '/clients/cli-1');
  });

  test('delete apunta a /clients/{id} con DELETE', () async {
    final List<RecordedRequest> requests = <RecordedRequest>[];
    final ClientsRepository repository = buildRepository(
      recordingClient(
        requests,
        (_) => jsonResponse(<String, String>{'message': 'recurso eliminado'}),
      ),
    );

    await repository.delete('cli-1');

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/clients/cli-1');
  });

  test('propaga el 403 cuando falta el permiso clients:read', () async {
    final ClientsRepository repository = buildRepository(
      MockClient(
        (_) async => jsonResponse(<String, String>{
          'message':
              'Acceso denegado: no tienes permisos para realizar esta acción',
        }, status: 403),
      ),
    );

    await expectLater(
      repository.fetchAll(),
      throwsA(
        isA<ForbiddenException>().having(
          (ForbiddenException e) => e.message,
          'message',
          contains('Acceso denegado'),
        ),
      ),
    );
  });

  test('Client.fromJson tolera campos ausentes', () {
    final Client client = Client.fromJson(<String, dynamic>{'id': 'cli-1'});

    expect(client.name, '');
    expect(client.nit, '');
    expect(client.isActive, isTrue);
    expect(client.createdAt, isNull);
  });
}
