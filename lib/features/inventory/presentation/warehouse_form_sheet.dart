import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../projects/application/project_scope.dart';
import '../../projects/application/projects_controller.dart';
import '../../projects/domain/project.dart';
import '../application/inventory_providers.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';

/// Alta de un almacén de obra (`POST /warehouses`).
Future<void> showWarehouseFormSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const _WarehouseFormSheet(),
    );

class _WarehouseFormSheet extends ConsumerStatefulWidget {
  const _WarehouseFormSheet();

  @override
  ConsumerState<_WarehouseFormSheet> createState() =>
      _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends ConsumerState<_WarehouseFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _location = TextEditingController();

  String? _projectId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // La obra que se está mirando es casi siempre la del almacén nuevo.
    _projectId = ref.read(activeProjectProvider)?.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
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
      await repository.createWarehouse(
        Warehouse(
          id: '',
          name: _name.text.trim(),
          projectId: _projectId,
          location: _location.text.trim(),
        ),
      );
      ref.invalidate(warehousesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(
        context,
        ref.read(stringsProvider).inventory.warehouseCreated,
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
    final AsyncValue<List<Project>> projects = ref.watch(
      projectsControllerProvider,
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
              SheetHeader(title: strings.newWarehouse),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              AsyncSection<List<Project>>(
                value: projects,
                errorMessage: strings.projectsError,
                onRetry: () => ref.invalidate(projectsControllerProvider),
                builder: (List<Project> list) => DropdownButtonFormField<String>(
                  initialValue: list.any((Project p) => p.id == _projectId)
                      ? _projectId
                      : null,
                  isExpanded: true,
                  dropdownColor: AppColors.surfaceHigh,
                  decoration: InputDecoration(
                    labelText: all.common.project,
                    prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                  ),
                  validator: (String? v) =>
                      v == null ? strings.projectRequired : null,
                  items: <DropdownMenuItem<String>>[
                    for (final Project project in list)
                      DropdownMenuItem<String>(
                        value: project.id,
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (String? id) => setState(() => _projectId = id),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.warehouseNameRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.warehouseName,
                  prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: all.common.location,
                  prefixIcon: const Icon(Icons.place_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.warehouseSubmit,
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
