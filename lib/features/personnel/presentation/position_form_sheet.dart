import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../application/personnel_providers.dart';
import '../domain/personnel_models.dart';

/// Alta de un cargo (`POST /positions`).
Future<void> showPositionFormSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const _PositionFormSheet(),
    );

class _PositionFormSheet extends ConsumerStatefulWidget {
  const _PositionFormSheet();

  @override
  ConsumerState<_PositionFormSheet> createState() => _PositionFormSheetState();
}

class _PositionFormSheetState extends ConsumerState<_PositionFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _salary = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(personnelRepositoryProvider).createPosition(
        Position(
          id: '',
          name: _name.text.trim(),
          baseSalary:
              double.tryParse(_salary.text.trim().replaceAll(',', '.')) ?? 0,
        ),
      );
      ref.invalidate(positionsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      final PersonnelStrings strings = ref.read(stringsProvider).personnel;
      showAppToast(context, strings.positionCreated);
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
    final PersonnelStrings strings = ref.watch(stringsProvider).personnel;

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
              SheetHeader(title: strings.newPosition),
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
                textCapitalization: TextCapitalization.words,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.positionNameRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.positionName,
                  prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _salary,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.amount,
                decoration: InputDecoration(
                  labelText: strings.baseSalaryLabel,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.positionSubmit,
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