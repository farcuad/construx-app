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
              label: const Text('Nuevo'),
            )
          : null,
      body: ProjectScope(
        emptyMessage: 'Los gastos se imputan a una obra. Crea la primera.',
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

    return AsyncSection<List<Expense>>(
      value: expenses,
      errorMessage: 'No se pudieron cargar los gastos.',
      onRetry: () => ref.invalidate(projectExpensesProvider(project.id)),
      builder: (List<Expense> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.payments_rounded,
              title: 'Sin gastos',
              message: '«${project.name}» no tiene gastos registrados todavía.',
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

class _Total extends StatelessWidget {
  const _Total({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
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
              label:
                  '${expenses.length} GASTO'
                  '${expenses.length == 1 ? '' : 'S'}',
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
                        expense.title.isEmpty ? 'Gasto' : expense.title,
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
      title: 'Eliminar gasto',
      message:
          'Se eliminará «${expense.title}» por '
          '${Fmt.money(expense.amount)}.',
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(expensesRepositoryProvider).delete(expense.id),
      successMessage: 'Gasto eliminado',
    );
    if (ok) ref.invalidate(projectExpensesProvider(expense.projectId));
  }
}
