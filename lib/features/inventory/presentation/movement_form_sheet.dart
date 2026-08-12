import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../purchases/application/purchases_providers.dart';
import '../../purchases/domain/purchase_order.dart';
import '../application/inventory_providers.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';

/// Registra una entrada o salida en [warehouse] (`POST /warehouses/movements`).
///
/// El almacén no se pregunta: el botón que abre esta hoja ya está dentro de su
/// tarjeta, así que preguntarlo otra vez solo daría ocasión de equivocarse.
Future<void> showMovementFormSheet(
  BuildContext context, {
  required Warehouse warehouse,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) => _MovementFormSheet(warehouse: warehouse),
);

class _MovementFormSheet extends ConsumerStatefulWidget {
  const _MovementFormSheet({required this.warehouse});

  final Warehouse warehouse;

  @override
  ConsumerState<_MovementFormSheet> createState() => _MovementFormSheetState();
}

class _MovementFormSheetState extends ConsumerState<_MovementFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _description = TextEditingController();

  MovementType _type = MovementType.input;
  String? _materialId;
  String? _referenceId;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final InventoryRepository repository = ref.read(
      inventoryRepositoryProvider,
    );

    try {
      await repository.registerMovement(
        StockMovement(
          id: '',
          warehouseId: widget.warehouse.id,
          materialId: _materialId!,
          type: _type,
          quantity:
              double.tryParse(_quantity.text.trim().replaceAll(',', '.')) ?? 0,
          referenceId: _referenceId,
          description: _description.text.trim(),
        ),
      );
      ref.invalidate(warehouseStockProvider(widget.warehouse.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(
        context,
        ref.read(stringsProvider).inventory.movementCreated,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings all = ref.watch(stringsProvider);
    final InventoryStrings strings = all.inventory;
    final AsyncValue<List<InventoryMaterial>> materials = ref.watch(
      materialsProvider,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SheetHeader(title: strings.movementTitle, bottom: 6),
              Text(
                widget.warehouse.name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              _TypePicker(
                type: _type,
                enabled: !_isSaving,
                label: strings.movementTypeLabel,
                onChanged: (MovementType type) => setState(() => _type = type),
              ),
              const SizedBox(height: 14),
              AsyncSection<List<InventoryMaterial>>(
                value: materials,
                errorMessage: strings.materialsError,
                onRetry: () => ref.invalidate(materialsProvider),
                builder: (List<InventoryMaterial> list) => list.isEmpty
                    ? ErrorBanner(message: strings.noMaterialsForMovement)
                    : DropdownButtonFormField<String>(
                        initialValue: _materialId,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceHigh,
                        decoration: InputDecoration(
                          labelText: strings.materialLabel,
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            size: 20,
                          ),
                        ),
                        validator: (String? v) =>
                            v == null ? strings.materialRequired : null,
                        items: <DropdownMenuItem<String>>[
                          for (final InventoryMaterial m in list)
                            DropdownMenuItem<String>(
                              value: m.id,
                              child: Text(
                                m.unit.isEmpty ? m.name : '${m.name} · ${m.unit}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5),
                              ),
                            ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (String? id) => setState(() => _materialId = id),
                      ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantity,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.amount,
                decoration: InputDecoration(
                  labelText: all.common.quantity,
                  prefixIcon: const Icon(Icons.straighten_rounded, size: 20),
                ),
              ),
              // La referencia solo tiene sentido al recibir: se ata la entrada
              // a la orden de compra que la trajo.
              if (_type == MovementType.input &&
                  widget.warehouse.projectId != null) ...<Widget>[
                const SizedBox(height: 14),
                _ReferencePicker(
                  projectId: widget.warehouse.projectId!,
                  value: _referenceId,
                  enabled: !_isSaving,
                  label: strings.referenceOptional,
                  onChanged: (String? id) => setState(() => _referenceId = id),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                enabled: !_isSaving,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: all.common.descriptionOptional,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.movementSubmit,
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada o salida, en dos botones grandes.
class _TypePicker extends ConsumerWidget {
  const _TypePicker({
    required this.type,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final MovementType type;
  final bool enabled;
  final String label;
  final ValueChanged<MovementType> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InventoryStrings strings = ref.watch(stringsProvider).inventory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (final MovementType option in MovementType.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _TypeButton(
                    label: strings.movement(option.apiValue, option.label),
                    icon: option == MovementType.input
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: option == MovementType.input
                        ? AppColors.success
                        : AppColors.warning,
                    selected: option == type,
                    enabled: enabled,
                    onTap: () => onChanged(option),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.55) : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 18, color: selected ? color : AppColors.textDisabled),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? color : AppColors.textDisabled,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Orden de compra que origina la entrada. Opcional: si las órdenes no cargan
/// o no hay ninguna, el campo simplemente no aparece y el movimiento se
/// registra sin referencia.
class _ReferencePicker extends ConsumerWidget {
  const _ReferencePicker({
    required this.projectId,
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final String projectId;
  final String? value;
  final bool enabled;
  final String label;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<PurchaseOrder> orders =
        ref.watch(projectPurchasesProvider(projectId)).valueOrNull ??
        const <PurchaseOrder>[];
    if (orders.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      initialValue: orders.any((PurchaseOrder o) => o.id == value)
          ? value
          : null,
      isExpanded: true,
      dropdownColor: AppColors.surfaceHigh,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.receipt_long_rounded, size: 20),
      ),
      items: <DropdownMenuItem<String>>[
        for (final PurchaseOrder order in orders)
          DropdownMenuItem<String>(
            value: order.id,
            child: Text(
              '${Fmt.money(order.totalAmount)} · ${Fmt.date(order.deliveryDate ?? order.createdAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}
