import '../../../core/network/api_client.dart';
import '../domain/audit_log.dart';

/// Registro de auditoría (`/audits-logs`).
///
/// Rutas `protectedBasic`: no comprueban la suscripción.
class AuditsRepository {
  const AuditsRepository(this._api);

  final ApiClient _api;

  /// `GET /audits-logs` — historial de la empresa del token.
  Future<List<AuditLog>> fetchAll() async =>
      (await _api.getList('/audits-logs'))
          .map(AuditLog.fromJson)
          .toList(growable: false);

  /// `POST /audits-logs` — deja constancia de un cambio.
  ///
  /// `company_id`, `user_id` e `ip_address` los rellena el backend.
  Future<AuditLog> record({
    required String action,
    required String tableName,
    String? rowId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async => AuditLog.fromJson(
    await _api.post(
      '/audits-logs',
      body: <String, dynamic>{
        'action': action,
        'table_name': tableName,
        'row_id': ?rowId,
        'old_values': ?oldValues,
        'new_values': ?newValues,
      },
    ),
  );
}
