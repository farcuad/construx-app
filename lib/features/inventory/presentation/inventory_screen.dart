import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/inventory_providers.dart';
import '../domain/inventory_models.dart';

/// Almacén elegido para ver sus existencias.
///
/// Vive fuera del widget para que volver a la pestaña no reinicie la elección.
final StateProvider<String?> selectedWarehouseProvider = StateProvider<String?>(
  (Ref ref) => null,
);

/// Inventario: existencias por almacén y catálogo de materiales.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static const String routeName = 'inventory';
  static const String routePath = '/inventory';

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: ModuleScaffold(
      title: 'Inventario',
      currentPath: routePath,
      onRefresh: () {
        ref.invalidate(warehousesProvider);
        ref.invalidate(materialsProvider);
        ref.invalidate(warehouseStockProvider);
      },
      bottom: const TabBar(
        tabs: <Widget>[
          Tab(text: 'Existencias'),
          Tab(text: 'Materiales'),
        ],
      ),
      body: const TabBarView(children: <Widget>[_StockTab(), _MaterialsTab()]),
    ),
  );
}

class _StockTab extends ConsumerWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Warehouse>> warehouses = ref.watch(
      warehousesProvider,
    );

    return AsyncSection<List<Warehouse>>(
      value: warehouses,
      errorMessage: 'No se pudieron cargar los almacenes.',
      onRetry: () => ref.invalidate(warehousesProvider),
      builder: (List<Warehouse> list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.warehouse_outlined,
            title: 'Sin almacenes',
            message: 'Crea un almacén para poder controlar existencias.',
          );
        }

        final String? selectedId = ref.watch(selectedWarehouseProvider);
        final Warehouse current = list.firstWhere(
          (Warehouse w) => w.id == selectedId,
          orElse: () => list.first,
        );

        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: _WarehousePicker(warehouses: list, current: current),
            ),
            Expanded(child: _StockList(warehouse: current)),
          ],
        );
      },
    );
  }
}

/// Desplegable de almacén, con el mismo aspecto que el de proyecto.
class _WarehousePicker extends ConsumerWidget {
  const _WarehousePicker({required this.warehouses, required this.current});

  final List<Warehouse> warehouses;
  final Warehouse current;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: <Widget>[
        const Icon(Icons.warehouse_outlined, size: 19, color: AppColors.orange),
        const SizedBox(width: 11),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.id,
              isExpanded: true,
              isDense: true,
              dropdownColor: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              icon: const Icon(
                Icons.expand_more_rounded,
                color: AppColors.textSecondary,
              ),
              items: <DropdownMenuItem<String>>[
                for (final Warehouse w in warehouses)
                  DropdownMenuItem<String>(
                    value: w.id,
                    child: Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5),
                    ),
                  ),
              ],
              onChanged: warehouses.length < 2
                  ? null
                  : (String? id) {
                      if (id != null) {
                        ref.read(selectedWarehouseProvider.notifier).state = id;
                      }
                    },
            ),
          ),
        ),
      ],
    ),
  );
}

class _StockList extends ConsumerWidget {
  const _StockList({required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<StockItem>> stock = ref.watch(
      warehouseStockProvider(warehouse.id),
    );

    return AsyncSection<List<StockItem>>(
      value: stock,
      errorMessage: 'No se pudieron cargar las existencias.',
      onRetry: () => ref.invalidate(warehouseStockProvider(warehouse.id)),
      builder: (List<StockItem> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Almacén vacío',
              message: '«${warehouse.name}» no tiene existencias registradas.',
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(warehouseStockProvider(warehouse.id)),
              itemBuilder: (BuildContext context, int index) {
                final StockItem item = data[index];
                // Sin stock no es un error, pero conviene que salte a la vista.
                final Color color = item.quantity <= 0
                    ? AppColors.danger
                    : AppColors.textPrimary;
                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.materialName.isEmpty
                                  ? 'Material'
                                  : item.materialName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.code.isNotEmpty)
                              InfoLine(
                                icon: Icons.qr_code_2_rounded,
                                text: item.code,
                                top: 4,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_qty(item.quantity)} ${item.unit}',
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Cantidades sin decimales cuando son enteras: «40 sacos», no «40.0 sacos».
  static String _qty(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

class _MaterialsTab extends ConsumerWidget {
  const _MaterialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InventoryMaterial>> materials = ref.watch(
      materialsProvider,
    );

    return AsyncSection<List<InventoryMaterial>>(
      value: materials,
      errorMessage: 'No se pudieron cargar los materiales.',
      onRetry: () => ref.invalidate(materialsProvider),
      builder: (List<InventoryMaterial> data) => data.isEmpty
          ? const EmptyState(
              icon: Icons.category_outlined,
              title: 'Sin materiales',
              message: 'El catálogo de materiales está vacío.',
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async => ref.invalidate(materialsProvider),
              itemBuilder: (BuildContext context, int index) {
                final InventoryMaterial m = data[index];
                return AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: <Widget>[
                      const LeadingIcon(
                        icon: Icons.category_outlined,
                        color: AppColors.cyanNeon,
                        size: 36,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              m.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (m.code.isNotEmpty)
                              InfoLine(
                                icon: Icons.qr_code_2_rounded,
                                text: m.code,
                                top: 4,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusChip(
                        label: m.unit.isEmpty ? '—' : m.unit,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
