import '../../../core/network/api_client.dart';
import '../domain/schedule_task.dart';

/// Cronograma de obra (`/schedule`).
class ScheduleRepository {
  const ScheduleRepository(this._api);

  final ApiClient _api;

  /// `GET /schedule/{project_id}`.
  Future<List<ScheduleTask>> fetchByProject(String projectId) async =>
      (await _api.getList('/schedule/$projectId'))
          .map(ScheduleTask.fromJson)
          .toList(growable: false);

  /// `POST /schedule/tasks`.
  Future<ScheduleTask> create(ScheduleTask task) async => ScheduleTask.fromJson(
    await _api.post('/schedule/tasks', body: task.toRequestBody()),
  );

  /// `PUT /schedule/tasks/{id}` — se envía la tarea completa.
  Future<ScheduleTask> update(ScheduleTask task) async => ScheduleTask.fromJson(
    await _api.put('/schedule/tasks/${task.id}', body: task.toRequestBody()),
  );

  /// `DELETE /schedule/tasks/{id}` → `204`.
  Future<void> delete(String id) => _api.delete('/schedule/tasks/$id');
}
