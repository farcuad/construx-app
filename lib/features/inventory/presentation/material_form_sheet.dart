import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../application/inventory_providers.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory_models.dart';

/// Alta de un material del catálogo (`POST /materials`).
Future<void> showMaterialFormSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const _MaterialFormSheet(),
    );

class _MaterialFormSheet extends ConsumerStatefulWidget {
  const _MaterialFormSheet();

  @override
  ConsumerState<_MaterialFormSheet> createState() => _MaterialFormSheetState();
}

class _MaterialFormSheetState extends ConsumerState<_MaterialFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _unit = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _unit.dispose();
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
      await repository.createMaterial(
        InventoryMaterial(
          id: '',
          name: _name.text.trim(),
          code: _code.text.trim(),
          unit: _unit.text.trim(),
        ),
      );
      ref.invalidate(materialsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(
        context,
        ref.read(stringsProvider).inventory.materialCreated,
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
    final InventoryStrings strings = ref.watch(stringsProvider).inventory;

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
              SheetHeader(title: strings.newMaterial),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.materialNameRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.materialName,
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _code,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.characters,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.materialCodeRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.materialCode,
                  prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unit,
                enabled: !_isSaving,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.materialUnitRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.materialUnit,
                  prefixIcon: const Icon(Icons.straighten_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.materialSubmit,
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
