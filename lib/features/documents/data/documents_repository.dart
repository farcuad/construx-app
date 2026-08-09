import '../../../core/network/api_client.dart';
import '../domain/document_models.dart';

/// Documentos del proyecto, sus tipos y su historial de versiones.
class DocumentsRepository {
  const DocumentsRepository(this._api);

  final ApiClient _api;

  // ── Tipos ───────────────────────────────────────────────────────────────

  /// `GET /documents/types`.
  Future<List<DocumentType>> fetchTypes() async => (await _api.getList(
    '/documents/types',
  )).map(DocumentType.fromJson).toList(growable: false);

  /// `POST /documents/types`.
  Future<DocumentType> createType({
    required String name,
    String description = '',
  }) async => DocumentType.fromJson(
    await _api.post(
      '/documents/types',
      body: <String, dynamic>{'name': name, 'description': description},
    ),
  );

  /// `PUT /documents/types/{id}` — responde solo con un mensaje.
  Future<void> updateType(String id, {String? name, String? description}) =>
      _api.put(
        '/documents/types/$id',
        body: <String, dynamic>{'name': ?name, 'description': ?description},
      );

  /// `DELETE /documents/types/{id}`.
  Future<void> deleteType(String id) => _api.delete('/documents/types/$id');

  // ── Documentos ──────────────────────────────────────────────────────────

  /// `GET /documents/project/{project_id}`.
  Future<List<ProjectDocument>> fetchByProject(String projectId) async =>
      (await _api.getList(
        '/documents/project/$projectId',
      )).map(ProjectDocument.fromJson).toList(growable: false);

  /// `GET /documents/{id}` — el documento con su historial de versiones.
  Future<ProjectDocument> fetchById(String id) async =>
      ProjectDocument.fromJson(await _api.getObject('/documents/$id'));

  /// `POST /documents` — crea el documento **y** su primera versión, por eso
  /// pide también los datos del archivo.
  Future<ProjectDocument> create({
    required String projectId,
    required String title,
    required String fileUrl,
    String? documentTypeId,
    String description = '',
    int fileSize = 0,
    String fileExtension = '',
    String changeLog = 'Versión inicial',
  }) async => ProjectDocument.fromJson(
    await _api.post(
      '/documents',
      body: <String, dynamic>{
        'project_id': projectId,
        'document_type_id': ?documentTypeId,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_size': fileSize,
        'file_extension': fileExtension,
        'change_log': changeLog,
      },
    ),
  );

  /// `PUT /documents/{id}` — responde solo con un mensaje.
  Future<void> update(
    String id, {
    String? title,
    String? description,
    String? documentTypeId,
  }) => _api.put(
    '/documents/$id',
    body: <String, dynamic>{
      'title': ?title,
      'description': ?description,
      'document_type_id': ?documentTypeId,
    },
  );

  /// `DELETE /documents/{id}`.
  Future<void> delete(String id) => _api.delete('/documents/$id');

  // ── Versiones ───────────────────────────────────────────────────────────

  /// `GET /documents/versions/{document_id}`.
  Future<List<DocumentVersion>> fetchVersions(String documentId) async =>
      (await _api.getList(
        '/documents/versions/$documentId',
      )).map(DocumentVersion.fromJson).toList(growable: false);

  /// `POST /documents/versions` — sube una versión nueva.
  Future<DocumentVersion> addVersion(DocumentVersion version) async =>
      DocumentVersion.fromJson(
        await _api.post('/documents/versions', body: version.toRequestBody()),
      );
}
