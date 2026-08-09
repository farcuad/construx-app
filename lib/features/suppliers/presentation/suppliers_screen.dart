import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/suppliers_providers.dart';
import '../domain/supplier.dart';

/// Proveedores de la empresa (`GET /supplier`).
class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  static const String routeName = 'suppliers';
  static const String routePath = '/suppliers';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Supplier>> suppliers = ref.watch(suppliersProvider);

    return ModuleScaffold(
      title: 'Proveedores',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(suppliersProvider),
      body: AsyncSection<List<Supplier>>(
        value: suppliers,
        errorMessage: 'No se pudieron cargar los proveedores.',
        onRetry: () => ref.invalidate(suppliersProvider),
        builder: (List<Supplier> data) => data.isEmpty
            ? const EmptyState(
                icon: Icons.local_shipping_rounded,
                title: 'Sin proveedores',
                message:
                    'Cuando tu empresa dé de alta proveedores, aparecerán aquí '
                    'para asociarlos a las órdenes de compra.',
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async => ref.invalidate(suppliersProvider),
                itemBuilder: (BuildContext context, int index) =>
                    _SupplierCard(supplier: data[index]),
              ),
      ),
    );
  }
}

class _SupplierCard extends ConsumerWidget {
  const _SupplierCard({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canDelete = user?.can(Perm.suppliersDelete) ?? false;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LeadingIcon(
            icon: Icons.local_shipping_rounded,
            color: AppColors.orange,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  supplier.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (supplier.nit.isNotEmpty)
                  InfoLine(
                    icon: Icons.badge_outlined,
                    text: 'NIT ${supplier.nit}',
                  ),
                if (supplier.phone.isNotEmpty)
                  InfoLine(icon: Icons.phone_outlined, text: supplier.phone),
                if (supplier.email.isNotEmpty)
                  InfoLine(
                    icon: Icons.mail_outline_rounded,
                    text: supplier.email,
                  ),
                if (supplier.address.isNotEmpty)
                  InfoLine(
                    icon: Icons.location_on_outlined,
                    text: supplier.address,
                  ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textDisabled,
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await confirmDestructive(
      context,
      title: 'Eliminar proveedor',
      message: 'Se eliminará «${supplier.name}».',
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(suppliersRepositoryProvider).delete(supplier.id),
      successMessage: 'Proveedor eliminado',
    );
    if (ok) ref.invalidate(suppliersProvider);
  }
}
