import '../../../core/network/api_client.dart';
import '../domain/personnel_models.dart';

/// Personal: cargos, empleados y contratos laborales.
///
/// Los `DELETE` de este módulo responden `204 No Content`; [ApiClient.delete]
/// lo tolera sin intentar decodificar cuerpo.
class PersonnelRepository {
  const PersonnelRepository(this._api);

  final ApiClient _api;

  // ── Cargos ──────────────────────────────────────────────────────────────

  /// `GET /positions`.
  Future<List<Position>> fetchPositions() async =>
      (await _api.getList('/positions'))
          .map(Position.fromJson)
          .toList(growable: false);

  /// `POST /positions`.
  Future<Position> createPosition(Position position) async => Position.fromJson(
    await _api.post('/positions', body: position.toRequestBody()),
  );

  /// `PUT /positions/{id}`.
  Future<Position> updatePosition(Position position) async => Position.fromJson(
    await _api.put('/positions/${position.id}', body: position.toRequestBody()),
  );

  /// `DELETE /positions/{id}` → `204`.
  Future<void> deletePosition(String id) => _api.delete('/positions/$id');

  // ── Empleados ───────────────────────────────────────────────────────────

  /// `GET /employees`.
  Future<List<Employee>> fetchEmployees() async =>
      (await _api.getList('/employees'))
          .map(Employee.fromJson)
          .toList(growable: false);

  /// `POST /employees`.
  Future<Employee> createEmployee(Employee employee) async => Employee.fromJson(
    await _api.post('/employees', body: employee.toRequestBody()),
  );

  /// `PUT /employees/{id}`.
  Future<Employee> updateEmployee(Employee employee) async => Employee.fromJson(
    await _api.put('/employees/${employee.id}', body: employee.toRequestBody()),
  );

  /// `DELETE /employees/{id}` → `204`.
  Future<void> deleteEmployee(String id) => _api.delete('/employees/$id');

  // ── Contratos ───────────────────────────────────────────────────────────

  /// `GET /contracts/{project_id}`.
  Future<List<LaborContract>> fetchContracts(String projectId) async =>
      (await _api.getList('/contracts/$projectId'))
          .map(LaborContract.fromJson)
          .toList(growable: false);

  /// `POST /contracts`.
  Future<LaborContract> createContract(LaborContract contract) async =>
      LaborContract.fromJson(
        await _api.post('/contracts', body: contract.toRequestBody()),
      );

  /// `PUT /contracts/{id}`.
  Future<LaborContract> updateContract(LaborContract contract) async =>
      LaborContract.fromJson(
        await _api.put(
          '/contracts/${contract.id}',
          body: contract.toUpdateBody(),
        ),
      );

  /// `DELETE /contracts/{id}` → `204`.
  Future<void> deleteContract(String id) => _api.delete('/contracts/$id');
}
