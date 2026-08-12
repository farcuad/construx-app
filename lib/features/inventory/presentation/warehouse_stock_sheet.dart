import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/sheet_header.dart';
import '../application/inventory_providers.dart';
import '../domain/inventory_models.dart';

/// Qué materiales hay en [warehouse] (`GET /inventory/stock/{warehouse_id}`).
Future<void> showWarehouseStockSheet(
  BuildContext context, {
  required Warehouse warehouse,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) => _WarehouseStockSheet(warehouse: warehouse),
);

class _WarehouseStockSheet extends ConsumerWidget {
  const _WarehouseStockSheet({required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryStrings strings = ref.watch(stringsProvider).inventory;
    final AsyncValue<List<StockItem>> stock = ref.watch(
      warehouseStockProvider(warehouse.id),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SheetHeader(
              title: strings.stockTitleFor(warehouse.name),
              bottom: 8,
            ),
          ),
          Expanded(
            child: AsyncSection<List<StockItem>>(
              value: stock,
              errorMessage: strings.stockError,
              onRetry: () =>
                  ref.invalidate(warehouseStockProvider(warehouse.id)),
              builder: (List<StockItem> data) => data.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: strings.emptyWarehouseTitle,
                      message: strings.emptyWarehouseFor(warehouse.name),
                    )
                  : ModuleList(
                      itemCount: data.length,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      onRefresh: () async =>
                          ref.invalidate(warehouseStockProvider(warehouse.id)),
                      itemBuilder: (BuildContext context, int index) =>
                          _StockRow(item: data[index], strings: strings),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.item, required this.strings});

  final StockItem item;
  final InventoryStrings strings;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.materialName.isEmpty
                    ? strings.unnamedMaterial
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
          '${formatQuantity(item.quantity)} ${item.unit}',
          style: TextStyle(
            // Sin existencias no es un error, pero conviene que salte a la
            // vista antes de que alguien vaya a buscar el material.
            color: item.quantity <= 0
                ? AppColors.danger
                : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// Cantidades sin decimales cuando son enteras: «40 sacos», no «40.00 sacos».
String formatQuantity(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
