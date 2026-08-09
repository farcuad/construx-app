import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../../suppliers/application/suppliers_providers.dart';
import '../application/purchases_providers.dart';
import '../domain/purchase_order.dart';

/// Órdenes de compra de la obra seleccionada (`GET /purcharse/{project_id}`).
class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  static const String routeName = 'purchases';
  static const String routePath = '/purchases';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Órdenes de compra',
    currentPath: routePath,
    onRefresh: () {
      ref.invalidate(projectPurchasesProvider);
      ref.invalidate(suppliersProvider);
    },
    body: ProjectScope(
      emptyMessage: 'Las órdenes de compra se emiten para una obra.',
      builder: (BuildContext context, Project project) =>
          _PurchasesList(project: project),
    ),
  );
}

class _PurchasesList extends ConsumerWidget {
  const _PurchasesList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PurchaseOrder>> orders = ref.watch(
      projectPurchasesProvider(project.id),
    );
    // Índice id→nombre, para no recorrer la lista de proveedores por cada fila.
    final Map<String, String> supplierNames = ref.watch(supplierNamesProvider);

    return AsyncSection<List<PurchaseOrder>>(
      value: orders,
      errorMessage: 'No se pudieron cargar las órdenes de compra.',
      onRetry: () => ref.invalidate(projectPurchasesProvider(project.id)),
      builder: (List<PurchaseOrder> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_checkout_rounded,
              title: 'Sin órdenes de compra',
              message: '«${project.name}» no tiene compras registradas.',
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectPurchasesProvider(project.id)),
              itemBuilder: (BuildContext context, int index) => _OrderCard(
                order: data[index],
                supplierName: supplierNames[data[index].supplierId],
              ),
            ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, this.supplierName});

  final PurchaseOrder order;
  final String? supplierName;

  Color get _statusColor => switch (order.status) {
    PurchaseStatus.approved => AppColors.success,
    PurchaseStatus.received => AppColors.cyanNeon,
    PurchaseStatus.rejected => AppColors.danger,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canApprove =
        (user?.can(Perm.purchasesApprove) ?? false) &&
        order.status == PurchaseStatus.pending;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LeadingIcon(
                icon: Icons.shopping_cart_checkout_rounded,
                color: _statusColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            supplierName ?? 'Proveedor sin asignar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: order.status.isEmpty ? '—' : order.status,
                          color: _statusColor,
                        ),
                      ],
                    ),
                    InfoLine(
                      icon: Icons.local_shipping_outlined,
                      text: 'Entrega ${Fmt.date(order.deliveryDate)}',
                    ),
                    InfoLine(
                      icon: Icons.inventory_2_outlined,
                      text:
                          '${order.items.length} línea'
                          '${order.items.length == 1 ? '' : 's'}',
                    ),
                    if (order.notes.isNotEmpty)
                      InfoLine(icon: Icons.notes_rounded, text: order.notes),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: LabeledValue(
                  label: 'TOTAL',
                  value: Fmt.money(order.totalAmount),
                  color: AppColors.orangeNeon,
                ),
              ),
              if (canApprove)
                FilledButton.icon(
                  onPressed: () => _approve(context, ref),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Aprobar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(purchasesRepositoryProvider).approve(order.id),
      successMessage: 'Orden aprobada',
    );
    if (ok) ref.invalidate(projectPurchasesProvider(order.projectId));
  }
}
