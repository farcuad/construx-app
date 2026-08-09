import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';

final Provider<InventoryRepository> inventoryRepositoryProvider =
    Provider<InventoryRepository>(
      (Ref ref) => InventoryRepository(ref.watch(apiClientProvider)),
    );

/// `GET /materials`.
final AutoDisposeFutureProvider<List<InventoryMaterial>> materialsProvider =
    FutureProvider.autoDispose<List<InventoryMaterial>>(
      (Ref ref) => ref.watch(inventoryRepositoryProvider).fetchMaterials(),
    );

/// `GET /warehouses`.
final AutoDisposeFutureProvider<List<Warehouse>> warehousesProvider =
    FutureProvider.autoDispose<List<Warehouse>>(
      (Ref ref) => ref.watch(inventoryRepositoryProvider).fetchWarehouses(),
    );

/// `GET /inventory/stock/{warehouse_id}`, cacheado por almacén.
final AutoDisposeFutureProviderFamily<List<StockItem>, String>
warehouseStockProvider =
    FutureProvider.autoDispose.family<List<StockItem>, String>(
      (Ref ref, String warehouseId) =>
          ref.watch(inventoryRepositoryProvider).fetchStock(warehouseId),
    );
