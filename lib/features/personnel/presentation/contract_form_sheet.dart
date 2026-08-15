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
import '../application/personnel_providers.dart';
import '../domain/personnel_models.dart';

/// Alta de un contrato laboral en [projectId] (`POST /contracts`).
Future<void> showContractFormSheet(
  BuildContext context, {
  required String projectId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) =>
      _ContractFormSheet(projectId: projectId),
);

class _ContractFormSheet extends ConsumerStatefulWidget {
  const _ContractFormSheet({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_ContractFormSheet> createState() => _ContractFormSheetState();
}

class _ContractFormSheetState extends ConsumerState<_ContractFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _salary = TextEditingController();

  String? _employeeId;
  String? _contractType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _salary.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        (start ? _startDate : _endDate) ?? (start ? now : now.add(Duration(days: 30)));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(personnelRepositoryProvider).createContract(
        LaborContract(
          id: '',
          employeeId: _employeeId!,
          projectId: widget.projectId,
          contractType: _contractType ?? ContractType.indefinite,
          salary:
              double.tryParse(_salary.text.trim().replaceAll(',', '.')) ?? 0,
          startDate: _startDate,
          endDate: _endDate,
        ),
      );
      ref.invalidate(projectContractsProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop();
      final PersonnelStrings strings = ref.read(stringsProvider).personnel;
      showAppToast(context, strings.contractCreated);
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
    final AsyncValue<List<Employee>> employees = ref.watch(employeesProvider);

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
              SheetHeader(title: strings.newContract),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              AsyncSection<List<Employee>>(
                value: employees,
                errorMessage: strings.employeesError,
                onRetry: () => ref.invalidate(employeesProvider),
                builder: (List<Employee> list) {
                  if (list.isEmpty) {
                    return ErrorBanner(
                      message: strings.contractEmployeeNotFound,
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _employeeId,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceHigh,
                    decoration: InputDecoration(
                      labelText: strings.contractEmployee,
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (String? v) =>
                        v == null ? strings.contractEmployeeRequired : null,
                    items: <DropdownMenuItem<String>>[
                      for (final Employee e in list)
                        DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            e.fullName.isEmpty ? strings.unnamedEmployee : e.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5),
                          ),
                        ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (String? id) => setState(() => _employeeId = id),
                  );
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _contractType,
                isExpanded: true,
                dropdownColor: AppColors.surfaceHigh,
                decoration: InputDecoration(
                  labelText: strings.contractTypeLabel,
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                ),
                items: <DropdownMenuItem<String>>[
                  for (final String apiValue in ContractType.values)
                    DropdownMenuItem<String>(
                      value: apiValue,
                      child: Text(
                        strings.contractType(
                          apiValue,
                          ContractType.labelFor(apiValue),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5),
                      ),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (String? value) => setState(() => _contractType = value),
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
                  labelText: strings.contractSalary,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: _isSaving ? null : () => _pickDate(start: true),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: strings.contractStart,
                          prefixIcon: const Icon(Icons.event_rounded, size: 20),
                        ),
                        child: Text(
                          Fmt.date(_startDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _isSaving ? null : () => _pickDate(start: false),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: strings.contractEnd,
                          prefixIcon: const Icon(Icons.event_rounded, size: 20),
                        ),
                        child: Text(
                          Fmt.date(_endDate),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: strings.contractSubmit,
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