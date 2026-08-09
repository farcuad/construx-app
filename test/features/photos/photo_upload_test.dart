import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mi_app_constructora/core/network/api_client.dart';
import 'package:mi_app_constructora/core/network/api_exception.dart';
import 'package:mi_app_constructora/features/photos/data/photos_repository.dart';
import 'package:mi_app_constructora/features/photos/data/supabase_storage.dart';
import 'package:mi_app_constructora/features/photos/domain/project_photo.dart';

import '../../helpers/test_helpers.dart';

void main() {
  const String supabaseUrl = 'https://proyecto.supabase.co';
  const String anonKey = 'clave-publicable';
  const String bucket = 'photos';
  final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  SupabaseStorage storage(
    List<RecordedRequest> requests,
    http.Response Function(RecordedRequest) handler,
  ) => SupabaseStorage(
    url: supabaseUrl,
    anonKey: anonKey,
    bucket: bucket,
    httpClient: recordingClient(requests, handler),
  );

  group('SupabaseStorage', () {
    test('sube al endpoint de Storage con la clave publicable', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final SupabaseStorage store = storage(
        requests,
        (_) => jsonResponse(<String, dynamic>{'Key': 'photos/p1/foto.jpg'}),
      );

      final String url = await store.upload(
        objectPath: 'p1/foto.jpg',
        bytes: bytes,
      );

      final RecordedRequest request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        '$supabaseUrl/storage/v1/object/$bucket/p1/foto.jpg',
      );
      expect(request.headers['apikey'], anonKey);
      expect(request.headers['authorization'], 'Bearer $anonKey');
      expect(request.headers['content-type'], 'image/jpeg');
      expect(request.headers['x-upsert'], 'false');

      expect(
        url,
        '$supabaseUrl/storage/v1/object/public/$bucket/p1/foto.jpg',
        reason: 'devuelve la URL pública, que es la que guarda el ERP',
      );
    });

    test('traduce el error de Supabase a un mensaje legible', () async {
      final SupabaseStorage store = storage(
        <RecordedRequest>[],
        (_) => jsonResponse(<String, dynamic>{
          'statusCode': '409',
          'error': 'Duplicate',
          'message': 'El objeto ya existe',
        }, status: 409),
      );

      await expectLater(
        store.upload(objectPath: 'p1/foto.jpg', bytes: bytes),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.message,
            'message',
            'El objeto ya existe',
          ),
        ),
      );
    });

    test('sin credenciales avisa de que falta configurar el .env', () async {
      final SupabaseStorage store = SupabaseStorage(
        url: '',
        anonKey: '',
        httpClient: MockClient((_) async => jsonResponse(null)),
      );

      expect(store.isConfigured, isFalse);
      await expectLater(
        store.upload(objectPath: 'p1/foto.jpg', bytes: bytes),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.message,
            'message',
            contains('.env'),
          ),
        ),
      );
    });

    test('borrar algo que ya no existe no es un error', () async {
      final SupabaseStorage store = storage(
        <RecordedRequest>[],
        (_) => textResponse('Not found', status: 404),
      );

      await expectLater(store.remove('p1/foto.jpg'), completes);
    });

    test('deduce la ruta del objeto a partir de la URL pública', () {
      final SupabaseStorage store = SupabaseStorage(
        url: supabaseUrl,
        anonKey: anonKey,
        bucket: bucket,
        httpClient: MockClient((_) async => jsonResponse(null)),
      );

      expect(
        store.objectPathOf(
          '$supabaseUrl/storage/v1/object/public/$bucket/p1/foto.jpg',
        ),
        'p1/foto.jpg',
      );
      expect(
        store.objectPathOf('https://otro-sitio.com/foto.jpg'),
        isNull,
        reason: 'no es un archivo de nuestro bucket',
      );
    });

    test('el nombre del objeto va bajo el proyecto y no se repite', () {
      final String a = SupabaseStorage.buildObjectPath('p1', 'jpg');
      final String b = SupabaseStorage.buildObjectPath('p1', 'jpg');

      expect(a, startsWith('p1/'));
      expect(a, endsWith('.jpg'));
      expect(a, isNot(b));
    });

    test('el tipo MIME sale de la extensión', () {
      expect(SupabaseStorage.contentTypeFor('png'), 'image/png');
      expect(SupabaseStorage.contentTypeFor('.HEIC'), 'image/heic');
      expect(SupabaseStorage.contentTypeFor('jpg'), 'image/jpeg');
      expect(SupabaseStorage.contentTypeFor('raro'), 'image/jpeg');
    });
  });

  group('PhotosRepository · subida', () {
    /// Repositorio con Supabase y ERP simulados por separado.
    ({
      PhotosRepository repository,
      List<RecordedRequest> storage,
      List<RecordedRequest> api,
    })
    build({http.Response Function(RecordedRequest)? apiHandler}) {
      final List<RecordedRequest> storageRequests = <RecordedRequest>[];
      final List<RecordedRequest> apiRequests = <RecordedRequest>[];

      return (
        repository: PhotosRepository(
          ApiClient(
            baseUrl: 'https://api.test',
            httpClient: recordingClient(
              apiRequests,
              apiHandler ??
                  (RecordedRequest r) => jsonResponse(<String, dynamic>{
                    'id': 'ph1',
                    'project_id': 'p1',
                    'photo_url': r.json['photo_url'],
                  }),
            ),
          ),
          storage: SupabaseStorage(
            url: supabaseUrl,
            anonKey: anonKey,
            bucket: bucket,
            httpClient: recordingClient(
              storageRequests,
              (_) => jsonResponse(<String, dynamic>{'Key': 'ok'}),
            ),
          ),
        ),
        storage: storageRequests,
        api: apiRequests,
      );
    }

    test('sube a Supabase y registra la URL pública en el ERP', () async {
      final ({
        PhotosRepository repository,
        List<RecordedRequest> storage,
        List<RecordedRequest> api,
      })
      env = build();

      final ProjectPhoto photo = await env.repository.upload(
        projectId: 'p1',
        bytes: bytes,
        description: 'Vaciado losa nivel 2',
      );

      // Primero Supabase…
      expect(env.storage.single.url.host, 'proyecto.supabase.co');
      // …y después el ERP, con la URL que devolvió la subida.
      final RecordedRequest registration = env.api.single;
      expect(registration.method, 'POST');
      expect(registration.url.path, '/photos');
      expect(
        registration.json['photo_url'],
        startsWith('$supabaseUrl/storage/v1/object/public/$bucket/p1/'),
      );
      expect(registration.json['description'], 'Vaciado losa nivel 2');
      expect(photo.photoUrl, registration.json['photo_url']);
    });

    test('si el ERP rechaza el registro, borra el archivo subido', () async {
      final ({
        PhotosRepository repository,
        List<RecordedRequest> storage,
        List<RecordedRequest> api,
      })
      env = build(
        apiHandler: (_) => textResponse('proyecto inválido', status: 400),
      );

      await expectLater(
        env.repository.upload(projectId: 'p1', bytes: bytes),
        throwsA(isA<BadRequestException>()),
      );

      expect(
        env.storage.map((RecordedRequest r) => r.method),
        <String>['POST', 'DELETE'],
        reason: 'no debe quedar un archivo huérfano ocupando el bucket',
      );
    });

    test('borrar la foto la quita del ERP y de Supabase', () async {
      final ({
        PhotosRepository repository,
        List<RecordedRequest> storage,
        List<RecordedRequest> api,
      })
      env = build(apiHandler: (_) => jsonResponse(null));

      await env.repository.deleteWithFile(
        const ProjectPhoto(
          id: 'ph1',
          projectId: 'p1',
          photoUrl:
              '$supabaseUrl/storage/v1/object/public/$bucket/p1/foto.jpg',
        ),
      );

      expect(env.api.single.method, 'DELETE');
      expect(env.api.single.url.path, '/photos/ph1');
      expect(env.storage.single.method, 'DELETE');
      expect(env.storage.single.url.path, '/storage/v1/object/photos/p1/foto.jpg');
    });

    test('una foto alojada fuera del bucket solo se borra del ERP', () async {
      final ({
        PhotosRepository repository,
        List<RecordedRequest> storage,
        List<RecordedRequest> api,
      })
      env = build(apiHandler: (_) => jsonResponse(null));

      await env.repository.deleteWithFile(
        const ProjectPhoto(
          id: 'ph1',
          projectId: 'p1',
          photoUrl: 'https://otro-storage.com/foto.jpg',
        ),
      );

      expect(env.api, hasLength(1));
      expect(env.storage, isEmpty);
    });

    test('el cuerpo que se sube son los bytes de la imagen', () async {
      final List<RecordedRequest> requests = <RecordedRequest>[];
      final SupabaseStorage store = storage(
        requests,
        (_) => jsonResponse(<String, dynamic>{'Key': 'ok'}),
      );

      await store.upload(
        objectPath: 'p1/foto.png',
        bytes: Uint8List.fromList(utf8.encode('PNG-falso')),
        contentType: 'image/png',
      );

      expect(requests.single.body, 'PNG-falso');
      expect(requests.single.headers['content-type'], 'image/png');
    });
  });
}
