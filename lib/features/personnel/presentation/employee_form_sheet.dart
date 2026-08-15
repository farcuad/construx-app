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
import '../application/personnel_providers.dart';
import '../domain/personnel_models.dart';

/// Alta de un empleado (`POST /employees`).
Future<void> showEmployeeFormSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => const _EmployeeFormSheet(),
    );

class _EmployeeFormSheet extends ConsumerStatefulWidget {
  const _EmployeeFormSheet();

  @override
  ConsumerState<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<_EmployeeFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _dni = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();

  String? _positionId;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _dni.dispose();
    _phone.dispose();
    _email.dispose();
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
      await ref.read(personnelRepositoryProvider).createEmployee(
        Employee(
          id: '',
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          positionId: _positionId,
          dni: _dni.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
        ),
      );
      ref.invalidate(employeesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      final PersonnelStrings strings = ref.read(stringsProvider).personnel;
      showAppToast(context, strings.employeeCreated);
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
    final PersonnelStrings strings = all.personnel;
    final AsyncValue<List<Position>> positions = ref.watch(positionsProvider);

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
              SheetHeader(title: strings.newEmployee),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _firstName,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.employeeFirstNameRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.employeeFirstName,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _lastName,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                validator: (String? v) => Validators.required(
                  v,
                  message: strings.employeeLastNameRequired,
                ),
                decoration: InputDecoration(
                  labelText: strings.employeeLastName,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              AsyncSection<List<Position>>(
                value: positions,
                errorMessage: strings.positionsError,
                onRetry: () => ref.invalidate(positionsProvider),
                builder: (List<Position> list) =>
                    DropdownButtonFormField<String>(
                      initialValue: _positionId,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceHigh,
                      decoration: InputDecoration(
                        labelText: strings.employeePosition,
                        prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                      ),
                      items: <DropdownMenuItem<String>>[
                        if (list.isNotEmpty)
                          for (final Position p in list)
                            DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14.5),
                              ),
                            ),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (String? id) => setState(() => _positionId = id),
                    ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dni,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: strings.employeeDni,
                  prefixIcon: const Icon(Icons.credit_card_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: all.common.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                enabled: !_isSaving,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? null
                    : Validators.email(v),
                decoration: InputDecoration(
                  labelText: all.common.email,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.employeeSubmit,
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