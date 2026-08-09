import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../domain/attendance_models.dart';

/// Asistencia diaria por proyecto (`/attendance`).
class AttendanceRepository {
  const AttendanceRepository(this._api);

  final ApiClient _api;

  /// `GET /attendance/{project_id}?date=YYYY-MM-DD`.
  ///
  /// Devuelve `null` cuando aún no se ha pasado lista ese día: el backend
  /// responde `404`, que aquí es un caso normal y no un error de la app.
  Future<Attendance?> fetchByDate(String projectId, DateTime date) async {
    try {
      return Attendance.fromJson(
        await _api.getObject(
          '/attendance/$projectId',
          query: <String, dynamic>{'date': Fmt.apiDate(date)},
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  /// `POST /attendance` — guarda la jornada con todas sus marcas.
  Future<Attendance> save(Attendance attendance) async => Attendance.fromJson(
    await _api.post('/attendance', body: attendance.toRequestBody()),
  );

  /// `PUT /attendance/logs/{id}` — corrige la marca de un empleado.
  Future<void> updateLog(
    String logId, {
    required AttendanceStatus status,
    required double hoursWorked,
    String notes = '',
  }) => _api.put(
    '/attendance/logs/$logId',
    body: <String, dynamic>{
      'status': status.apiValue,
      'hours_worked': hoursWorked,
      'notes': notes,
    },
  );

  /// `DELETE /attendance/{id}` → `204`.
  Future<void> delete(String id) => _api.delete('/attendance/$id');
}
