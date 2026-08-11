import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/finance_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../application/expenses_providers.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';

/// Abre el formulario de gasto como hoja inferior.
///
/// Con [expense] edita; sin él, crea uno nuevo para [projectId].
Future<void> showExpenseFormSheet(
  BuildContext context, {
  required String projectId,
  Expense? expense,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) =>
      _ExpenseFormSheet(projectId: projectId, expense: expense),
);

class _ExpenseFormSheet extends ConsumerStatefulWidget {
  const _ExpenseFormSheet({required this.projectId, this.expense});

  final String projectId;
  final Expense? expense;

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late DateTime _date;

  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final Expense? expense = widget.expense;
    _title = TextEditingController(text: expense?.title ?? '');
    _amount = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _description = TextEditingController(text: expense?.description ?? '');
    _date = expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      // Un gasto no puede ser futuro: se registra lo ya pagado.
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final double amount =
        double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;
    final ExpensesRepository repository = ref.read(expensesRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.update(
          widget.expense!.id,
          title: _title.text.trim(),
          amount: amount,
          expenseDate: _date,
          description: _description.text.trim(),
        );
      } else {
        await repository.create(
          Expense(
            id: '',
            projectId: widget.projectId,
            title: _title.text.trim(),
            amount: amount,
            expenseDate: _date,
            description: _description.text.trim(),
          ),
        );
      }
      ref.invalidate(projectExpensesProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop();
      final ExpensesStrings strings = ref.read(stringsProvider).expenses;
      showAppToast(context, _isEditing ? strings.updated : strings.created);
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
    final ExpensesStrings strings = all.expenses;

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
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isEditing ? strings.formEdit : strings.formNew,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _title,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.sentences,
                validator: (String? v) =>
                    Validators.required(v, message: strings.conceptRequired),
                decoration: InputDecoration(
                  labelText: strings.concept,
                  prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.amount,
                decoration: InputDecoration(
                  labelText: all.common.amount,
                  prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _isSaving ? null : _pickDate,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: strings.expenseDate,
                    prefixIcon: const Icon(Icons.event_rounded, size: 20),
                  ),
                  child: Text(
                    Fmt.date(_date),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                enabled: !_isSaving,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: all.common.descriptionOptional,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: _isEditing ? all.common.saveChanges : strings.submit,
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
