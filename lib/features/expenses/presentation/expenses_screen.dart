import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/finance_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/application/project_scope.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/expenses_providers.dart';
import '../domain/expense.dart';
import 'expense_form_sheet.dart';

/// Gastos de la obra seleccionada (`GET /expenses/{project_id}`).
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  static const String routeName = 'expenses';
  static const String routePath = '/expenses';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final Project? project = ref.watch(activeProjectProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canCreate =
        (user?.can(Perm.expensesCreate) ?? false) && project != null;

    return ModuleScaffold(
      title: 'Gastos',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(projectExpensesProvider),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () =>
                  showExpenseFormSheet(context, projectId: project.id),
              icon: const Icon(Icons.add_rounded),
              label: Text(strings.common.newItem),
            )
          : null,
      body: ProjectScope(
        emptyMessage: strings.expenses.needsProject,
        builder: (BuildContext context, Project project) =>
            _ExpensesList(project: project),
      ),
    );
  }
}

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Expense>> expenses = ref.watch(
      projectExpensesProvider(project.id),
    );
    final ExpensesStrings strings = ref.watch(stringsProvider).expenses;

    return AsyncSection<List<Expense>>(
      value: expenses,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(projectExpensesProvider(project.id)),
      builder: (List<Expense> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.payments_rounded,
              title: strings.emptyTitle,
              message: strings.emptyFor(project.name),
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectExpensesProvider(project.id)),
              header: _Total(expenses: data),
              itemBuilder: (BuildContext context, int index) =>
                  _ExpenseCard(expense: data[index]),
            ),
    );
  }
}

class _Total extends ConsumerWidget {
  const _Total({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double total = expenses.fold<double>(
      0,
      (double sum, Expense e) => sum + e.amount,
    );

    return AppCard(
      glowColor: AppColors.warning,
      child: Row(
        children: <Widget>[
          const LeadingIcon(
            icon: Icons.summarize_rounded,
            color: AppColors.warning,
            size: 38,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: LabeledValue(
              label: ref.watch(stringsProvider).expenses.count(expenses.length),
              value: Fmt.money(total),
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final AppStrings strings = ref.watch(stringsProvider);
    final bool canUpdate = user?.can(Perm.expensesUpdate) ?? false;
    final bool canDelete = user?.can(Perm.expensesDelete) ?? false;

    return AppCard(
      onTap: canUpdate
          ? () => showExpenseFormSheet(
              context,
              projectId: expense.projectId,
              expense: expense,
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LeadingIcon(
            icon: Icons.receipt_long_rounded,
            color: AppColors.warning,
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
                        expense.title.isEmpty
                            ? strings.expenses.untitled
                            : expense.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Fmt.money(expense.amount),
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                InfoLine(
                  icon: Icons.event_rounded,
                  text: Fmt.date(expense.expenseDate ?? expense.createdAt),
                ),
                if (expense.description.isNotEmpty)
                  InfoLine(
                    icon: Icons.notes_rounded,
                    text: expense.description,
                  ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: strings.common.delete,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              color: AppColors.textDisabled,
              onPressed: () => _delete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ExpensesStrings strings = ref.read(stringsProvider).expenses;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.deleteTitle,
      message: strings.deleteBody(expense.title, Fmt.money(expense.amount)),
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(expensesRepositoryProvider).delete(expense.id),
      successMessage: strings.deleted,
    );
    if (ok) ref.invalidate(projectExpensesProvider(expense.projectId));
  }
}
