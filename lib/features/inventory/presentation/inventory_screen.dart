import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/inventory_providers.dart';
import '../domain/inventory_models.dart';
import 'material_form_sheet.dart';
import 'movement_form_sheet.dart';
import 'warehouse_form_sheet.dart';
import 'warehouse_stock_sheet.dart';

/// Inventario: almacenes de obra y catálogo de materiales.
///
/// Es un `StatefulWidget` por el `TabController`: el botón flotante cambia con
/// la pestaña (almacén nuevo / material nuevo) y hay que enterarse también
/// cuando se cambia deslizando, no solo al tocar la pestaña.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  static const String routeName = 'inventory';
  static const String routePath = '/inventory';

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings all = ref.watch(stringsProvider);
    final InventoryStrings strings = all.inventory;
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canManage = user?.can(Perm.inventoryManage) ?? false;

    return ModuleScaffold(
      title: 'Inventario',
      currentPath: InventoryScreen.routePath,
      onRefresh: () {
        ref.invalidate(warehousesProvider);
        ref.invalidate(materialsProvider);
        ref.invalidate(warehouseStockProvider);
      },
      bottom: TabBar(
        controller: _tabs,
        tabs: <Widget>[
          Tab(text: strings.tabWarehouses),
          Tab(text: strings.tabMaterials),
        ],
      ),
      floatingActionButton: canManage
          // Solo se redibuja el botón al cambiar de pestaña, no la pantalla.
          ? ListenableBuilder(
              listenable: _tabs.animation!,
              builder: (BuildContext context, Widget? _) {
                final bool onMaterials = _tabs.index == 1;
                return FloatingActionButton.extended(
                  onPressed: () => onMaterials
                      ? showMaterialFormSheet(context)
                      : showWarehouseFormSheet(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    onMaterials ? strings.newMaterial : strings.newWarehouse,
                  ),
                );
              },
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _WarehousesTab(canManage: canManage),
          const _MaterialsTab(),
        ],
      ),
    );
  }
}

/// Almacenes de la empresa, cada uno con sus dos acciones.
class _WarehousesTab extends ConsumerWidget {
  const _WarehousesTab({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Warehouse>> warehouses = ref.watch(
      warehousesProvider,
    );
    final InventoryStrings strings = ref.watch(stringsProvider).inventory;

    return AsyncSection<List<Warehouse>>(
      value: warehouses,
      errorMessage: strings.warehousesError,
      onRetry: () => ref.invalidate(warehousesProvider),
      builder: (List<Warehouse> list) => list.isEmpty
          ? EmptyState(
              icon: Icons.warehouse_outlined,
              title: strings.noWarehousesTitle,
              message: strings.noWarehousesMessage,
            )
          : ModuleList(
              itemCount: list.length,
              onRefresh: () async => ref.invalidate(warehousesProvider),
              itemBuilder: (BuildContext context, int index) => _WarehouseCard(
                warehouse: list[index],
                canManage: canManage,
                strings: strings,
              ),
            ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  const _WarehouseCard({
    required this.warehouse,
    required this.canManage,
    required this.strings,
  });

  final Warehouse warehouse;
  final bool canManage;
  final InventoryStrings strings;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
    child: Row(
      children: <Widget>[
        const LeadingIcon(
          icon: Icons.warehouse_outlined,
          color: AppColors.orange,
          size: 38,
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                warehouse.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (warehouse.location.isNotEmpty)
                InfoLine(
                  icon: Icons.place_outlined,
                  text: warehouse.location,
                  top: 4,
                ),
            ],
          ),
        ),
        if (canManage)
          IconButton(
            tooltip: strings.movementSubmit,
            onPressed: () =>
                showMovementFormSheet(context, warehouse: warehouse),
            icon: const Icon(Icons.swap_vert_rounded, size: 21),
            color: AppColors.orangeNeon,
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          tooltip: strings.viewStock,
          onPressed: () => showWarehouseStockSheet(context, warehouse: warehouse),
          icon: const Icon(Icons.visibility_outlined, size: 20),
          color: AppColors.cyanNeon,
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class _MaterialsTab extends ConsumerWidget {
  const _MaterialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InventoryMaterial>> materials = ref.watch(
      materialsProvider,
    );
    final InventoryStrings strings = ref.watch(stringsProvider).inventory;

    return AsyncSection<List<InventoryMaterial>>(
      value: materials,
      errorMessage: strings.materialsError,
      onRetry: () => ref.invalidate(materialsProvider),
      builder: (List<InventoryMaterial> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              title: strings.noMaterialsTitle,
              message: strings.noMaterialsMessage,
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
