import '../../../core/network/api_client.dart';
import '../domain/project.dart';
import '../domain/project_kpis.dart';

/// Acceso a los endpoints de proyectos y al dashboard financiero.
class ProjectsRepository {
  const ProjectsRepository(this._api);

  final ApiClient _api;

  /// `GET /projects` — proyectos de la empresa del token.
  Future<List<Project>> fetchAll() async {
    final List<Map<String, dynamic>> raw = await _api.getList('/projects');
    return raw.map(Project.fromJson).toList(growable: false);
  }

  /// `POST /projects`.
  ///
  /// Puede fallar con `402` si el plan de suscripción alcanzó su límite de
  /// proyectos.
  Future<Project> create(Project project) async => Project.fromJson(
    await _api.post('/projects', body: project.toRequestBody()),
  );

  /// `PUT /projects/{id}`.
  Future<Project> update(Project project) async => Project.fromJson(
    await _api.put('/projects/${project.id}', body: project.toRequestBody()),
  );

  /// `DELETE /projects/{id}` — devuelve `409` si el proyecto tiene datos
  /// asociados que impiden borrarlo.
  Future<void> delete(String id) => _api.delete('/projects/$id');

  /// `GET /dashboard/financial/{project_id}`.
  Future<ProjectKpis> fetchKpis(String projectId) async => ProjectKpis.fromJson(
    await _api.getObject('/dashboard/financial/$projectId'),
  );
}
