import 'dart:typed_data';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/project_photo.dart';
import 'supabase_storage.dart';

/// Galería de fotos de obra.
///
/// El archivo va a **Supabase Storage** y el ERP solo guarda los metadatos:
/// `POST /photos` recibe la URL pública que devuelve la subida. Este
/// repositorio coordina los dos pasos.
class PhotosRepository {
  PhotosRepository(this._api, {SupabaseStorage? storage})
    : _providedStorage = storage;

  final ApiClient _api;
  final SupabaseStorage? _providedStorage;
  SupabaseStorage? _lazyStorage;

  /// Se crea al primer uso: la mayoría de pantallas solo listan fotos y no
  /// necesitan abrir una conexión con Supabase.
  SupabaseStorage get _storage =>
      _lazyStorage ??= _providedStorage ?? SupabaseStorage();

  /// `true` si hay credenciales de Supabase configuradas.
  ///
  /// Se responde sin tocar [_storage] para no abrir una conexión solo por
  /// preguntar si se puede subir.
  bool get canUpload => _providedStorage?.isConfigured ?? AppConfig.hasSupabase;

  /// `GET /photos/{project_id}`.
  Future<List<ProjectPhoto>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/photos/$projectId',
      )).map(ProjectPhoto.fromJson).toList(growable: false);

  /// Sube la imagen a Supabase y registra sus metadatos en el ERP.
  ///
  /// Si el backend rechaza el registro, se borra el archivo recién subido para
  /// no dejar huérfanos ocupando el bucket.
  Future<ProjectPhoto> upload({
    required String projectId,
    required Uint8List bytes,
    String fileExtension = 'jpg',
    String description = '',
    String? taskId,
    String? dailyReportId,
    double? latitude,
    double? longitude,
  }) async {
    final String objectPath = SupabaseStorage.buildObjectPath(
      projectId,
      fileExtension,
    );

    final String photoUrl = await _storage.upload(
      objectPath: objectPath,
      bytes: bytes,
      contentType: SupabaseStorage.contentTypeFor(fileExtension),
    );

    try {
      return await create(
        ProjectPhoto(
          id: '',
          projectId: projectId,
          photoUrl: photoUrl,
          taskId: taskId,
          dailyReportId: dailyReportId,
          description: description,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } on ApiException {
      // Compensación: el archivo ya está arriba pero nadie lo referencia.
      try {
        await _storage.remove(objectPath);
      } on ApiException {
        // Si tampoco se puede borrar, manda el error original del registro.
      }
      rethrow;
    }
  }

  /// `POST /photos` — registra solo los metadatos de una URL ya existente.
  Future<ProjectPhoto> create(ProjectPhoto photo) async =>
      ProjectPhoto.fromJson(
        await _api.post('/photos', body: photo.toRequestBody()),
      );

  /// `PUT /photos/{id}` — responde solo con un mensaje.
  Future<void> update(
    String id, {
    String? description,
    double? latitude,
    double? longitude,
  }) => _api.put(
    '/photos/$id',
    body: <String, dynamic>{
      'description': ?description,
      'latitude': ?latitude,
      'longitude': ?longitude,
    },
  );

  /// `DELETE /photos/{id}` — borra solo el registro del ERP.
  Future<void> delete(String id) => _api.delete('/photos/$id');

  /// Borra la foto de los dos sitios: primero el registro del ERP y después
  /// el archivo de Supabase.
  ///
  /// Ese orden es el seguro: si fallara el borrado del archivo quedaría un
  /// huérfano invisible, mientras que al revés quedaría una foto listada que
  /// ya no se puede abrir.
  Future<void> deleteWithFile(ProjectPhoto photo) async {
    await delete(photo.id);
    final String? objectPath = _storage.objectPathOf(photo.photoUrl);
    if (objectPath == null) return; // No es un archivo nuestro.
    try {
      await _storage.remove(objectPath);
    } on ApiException {
      // El registro ya no existe: no se molesta al usuario con esto.
    }
  }

  /// Cierra la conexión con Supabase si se llegó a abrir.
  void close() {
    if (_providedStorage == null) _lazyStorage?.close();
  }
}
