import '../../../core/network/api_client.dart';
import '../domain/inventory_models.dart';

/// Inventario: catálogo de materiales, almacenes, movimientos y existencias.
class InventoryRepository {
  const InventoryRepository(this._api);

  final ApiClient _api;

  // ── Materiales ──────────────────────────────────────────────────────────

  /// `GET /materials`.
  Future<List<InventoryMaterial>> fetchMaterials() async => (await _api.getList(
    '/materials',
  )).map(InventoryMaterial.fromJson).toList(growable: false);

  /// `POST /materials`.
  Future<InventoryMaterial> createMaterial(InventoryMaterial material) async =>
      InventoryMaterial.fromJson(
        await _api.post('/materials', body: material.toRequestBody()),
      );

  /// `PUT /materials/{id}`.
  Future<InventoryMaterial> updateMaterial(InventoryMaterial material) async =>
      InventoryMaterial.fromJson(
        await _api.put(
          '/materials/${material.id}',
          body: material.toRequestBody(),
        ),
      );

  /// `DELETE /materials/{id}`.
  Future<void> deleteMaterial(String id) => _api.delete('/materials/$id');

  // ── Almacenes ───────────────────────────────────────────────────────────

  /// `GET /warehouses`.
  Future<List<Warehouse>> fetchWarehouses() async => (await _api.getList(
    '/warehouses',
  )).map(Warehouse.fromJson).toList(growable: false);

  /// `POST /warehouses`.
  Future<Warehouse> createWarehouse(Warehouse warehouse) async =>
      Warehouse.fromJson(
        await _api.post('/warehouses', body: warehouse.toRequestBody()),
      );

  /// `PUT /warehouses/{id}` — solo nombre y ubicación.
  Future<Warehouse> updateWarehouse(
    String id, {
    String? name,
    String? location,
  }) async => Warehouse.fromJson(
    await _api.put(
      '/warehouses/$id',
      body: <String, dynamic>{'name': ?name, 'location': ?location},
    ),
  );

  /// `DELETE /warehouses/{id}`.
  Future<void> deleteWarehouse(String id) => _api.delete('/warehouses/$id');

  // ── Movimientos y existencias ───────────────────────────────────────────

  /// `POST /warehouses/movements` — registra una entrada o salida.
  Future<StockMovement> registerMovement(StockMovement movement) async =>
      StockMovement.fromJson(
        await _api.post(
          '/warehouses/movements',
          body: movement.toRequestBody(),
        ),
      );

  /// `GET /inventory/stock/{warehouse_id}` — existencias por material.
  Future<List<StockItem>> fetchStock(String warehouseId) async =>
      (await _api.getList(
        '/inventory/stock/$warehouseId',
      )).map(StockItem.fromJson).toList(growable: false);
}
