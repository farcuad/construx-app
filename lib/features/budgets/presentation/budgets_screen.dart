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
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/budgets_providers.dart';
import '../domain/budget.dart';

/// Presupuestos de la obra seleccionada (`GET /budgets/{project_id}`).
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  static const String routeName = 'budgets';
  static const String routePath = '/budgets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return ModuleScaffold(
      title: 'Presupuestos',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(projectBudgetsProvider),
      body: ProjectScope(
        emptyMessage: strings.budgets.needsProject,
        builder: (BuildContext context, Project project) =>
            _BudgetsList(project: project),
      ),
    );
  }
}

class _BudgetsList extends ConsumerWidget {
  const _BudgetsList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Budget>> budgets = ref.watch(
      projectBudgetsProvider(project.id),
    );
    final BudgetsStrings strings = ref.watch(stringsProvider).budgets;

    return AsyncSection<List<Budget>>(
      value: budgets,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(projectBudgetsProvider(project.id)),
      builder: (List<Budget> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.request_quote_rounded,
              title: strings.emptyTitle,
              message: strings.emptyFor(project.name),
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectBudgetsProvider(project.id)),
              header: _Total(budgets: data),
              itemBuilder: (BuildContext context, int index) =>
                  _BudgetCard(budget: data[index]),
            ),
    );
  }
}

/// Suma de todos los presupuestos de la obra.
class _Total extends ConsumerWidget {
  const _Total({required this.budgets});

  final List<Budget> budgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double total = budgets.fold<double>(
      0,
      (double sum, Budget b) => sum + b.totalAmount,
    );

    return AppCard(
      glowColor: AppColors.orange,
      child: Row(
        children: <Widget>[
          const LeadingIcon(
            icon: Icons.functions_rounded,
            color: AppColors.orange,
            size: 38,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: LabeledValue(
              label: ref.watch(stringsProvider).budgets.count(budgets.length),
              value: Fmt.money(total),
              color: AppColors.orangeNeon,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canDelete = user?.can(Perm.budgetsDelete) ?? false;
    final AppStrings strings = ref.watch(stringsProvider);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        // El `ExpansionTile` trae divisores propios que aquí sobran: la tarjeta
        // ya está delimitada por su borde.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          iconColor: AppColors.orangeNeon,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            budget.title.isEmpty ? strings.budgets.untitled : budget.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${Fmt.money(budget.totalAmount)} · '
              '${strings.budgets.items(budget.items.length)}',
              style: const TextStyle(
                color: AppColors.orangeNeon,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: <Widget>[
            if (budget.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  budget.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            for (final BudgetItem item in budget.items) _ItemRow(item: item),
            if (canDelete)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, size: 17),
                  label: Text(strings.common.delete),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final BudgetsStrings strings = ref.read(stringsProvider).budgets;
    final bool confirmed = await confirmDestructive(
      context,
      title: strings.deleteTitle,
      message: strings.deleteBody(budget.title),
    );
    if (!confirmed || !context.mounted) return;

    final bool ok = await runWithFeedback(
      context,
      action: () => ref.read(budgetsRepositoryProvider).delete(budget.id),
      successMessage: strings.deleted,
    );
    if (ok) ref.invalidate(projectBudgetsProvider(budget.projectId));
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final BudgetItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.description.isEmpty ? '—' : item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                ),
              ),
              Text(
                '${item.quantity} ${item.unit} × '
                '${Fmt.money(item.unitPrice)}'
                '${item.category.isEmpty ? '' : ' · ${item.category}'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          Fmt.money(item.total),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
