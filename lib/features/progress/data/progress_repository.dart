import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../domain/daily_report.dart';

/// Reportes diarios de avance de obra (`/progress`).
class ProgressRepository {
  const ProgressRepository(this._api);

  final ApiClient _api;

  /// `GET /progress/{project_id}?date=YYYY-MM-DD`.
  ///
  /// Devuelve `null` si ese día no se registró reporte: el `404` del backend
  /// es un caso esperado, no un fallo.
  Future<DailyReport?> fetchByDate(String projectId, DateTime date) async {
    try {
      return DailyReport.fromJson(
        await _api.getObject(
          '/progress/$projectId',
          query: <String, dynamic>{'date': Fmt.apiDate(date)},
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  /// `POST /progress/daily` — crea el reporte con sus avances por tarea.
  Future<DailyReport> create(DailyReport report) async => DailyReport.fromJson(
    await _api.post('/progress/daily', body: report.toRequestBody()),
  );

  /// `PUT /progress/daily/{id}` — responde solo con un mensaje.
  Future<void> update(
    String id, {
    String? weatherCondition,
    String? observations,
    DateTime? reportDate,
  }) => _api.put(
    '/progress/daily/$id',
    body: <String, dynamic>{
      'weather_condition': ?weatherCondition,
      'observations': ?observations,
      if (reportDate != null) 'report_date': Fmt.apiDateTime(reportDate),
    },
  );

  /// `DELETE /progress/daily/{id}`.
  Future<void> delete(String id) => _api.delete('/progress/daily/$id');
}
