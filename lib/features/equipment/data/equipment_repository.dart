import '../../../core/network/api_client.dart';
import '../domain/equipment_models.dart';

/// Maquinaria: catálogo, tipos, asignaciones a obra y mantenimientos.
class EquipmentRepository {
  const EquipmentRepository(this._api);

  final ApiClient _api;

  // ── Tipos ───────────────────────────────────────────────────────────────

  /// `GET /equipment/types`.
  Future<List<EquipmentType>> fetchTypes() async => (await _api.getList(
    '/equipment/types',
  )).map(EquipmentType.fromJson).toList(growable: false);

  /// `POST /equipment/types`.
  Future<EquipmentType> createType(String name) async => EquipmentType.fromJson(
    await _api.post('/equipment/types', body: <String, dynamic>{'name': name}),
  );

  // ── Maquinaria ──────────────────────────────────────────────────────────

  /// `GET /equipment`.
  Future<List<Equipment>> fetchAll() async => (await _api.getList(
    '/equipment',
  )).map(Equipment.fromJson).toList(growable: false);

  /// `POST /equipment`.
  Future<Equipment> create(Equipment equipment) async => Equipment.fromJson(
    await _api.post('/equipment', body: equipment.toRequestBody()),
  );

  /// `PUT /equipment/{id}`.
  Future<Equipment> update(Equipment equipment) async => Equipment.fromJson(
    await _api.put(
      '/equipment/${equipment.id}',
      body: equipment.toRequestBody(),
    ),
  );

  /// `DELETE /equipment/{id}`.
  Future<void> delete(String id) => _api.delete('/equipment/$id');

  // ── Asignaciones ────────────────────────────────────────────────────────

  /// `POST /equipment/assignments` — asigna la máquina a un proyecto.
  Future<EquipmentAssignment> assign(EquipmentAssignment assignment) async =>
      EquipmentAssignment.fromJson(
        await _api.post(
          '/equipment/assignments',
          body: assignment.toRequestBody(),
        ),
      );

  /// `GET /equipment/assignments/{equipment_id}`.
  Future<List<EquipmentAssignment>> fetchAssignments(
    String equipmentId,
  ) async => (await _api.getList(
    '/equipment/assignments/$equipmentId',
  )).map(EquipmentAssignment.fromJson).toList(growable: false);

  // ── Mantenimientos ──────────────────────────────────────────────────────

  /// `POST /equipment/maintenances`.
  Future<MaintenanceRecord> registerMaintenance(
    MaintenanceRecord record,
  ) async => MaintenanceRecord.fromJson(
    await _api.post('/equipment/maintenances', body: record.toRequestBody()),
  );

  /// `GET /equipment/maintenances/{equipment_id}`.
  Future<List<MaintenanceRecord>> fetchMaintenances(String equipmentId) async =>
      (await _api.getList(
        '/equipment/maintenances/$equipmentId',
      )).map(MaintenanceRecord.fromJson).toList(growable: false);
}
