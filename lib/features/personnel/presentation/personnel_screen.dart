import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/resources_strings.dart';
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
import '../application/personnel_providers.dart';
import '../domain/personnel_models.dart';
import 'contract_form_sheet.dart';
import 'employee_form_sheet.dart';
import 'position_form_sheet.dart';

/// Personal de la empresa: empleados, cargos y contratos laborales por obra.
class PersonnelScreen extends ConsumerStatefulWidget {
  const PersonnelScreen({super.key});

  static const String routeName = 'personnel';
  static const String routePath = '/personnel';

  @override
  ConsumerState<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends ConsumerState<PersonnelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PersonnelStrings strings = ref.watch(stringsProvider).personnel;
    final AuthUser? user = ref.watch(currentUserProvider);
    final bool canManage = user?.can(Perm.personnelManage) ?? false;
    final Project? project = ref.watch(activeProjectProvider);

    return ModuleScaffold(
      title: 'Personal',
      currentPath: PersonnelScreen.routePath,
      onRefresh: () {
        ref.invalidate(employeesProvider);
        ref.invalidate(positionsProvider);
        ref.invalidate(projectContractsProvider);
      },
      bottom: TabBar(
        controller: _tabs,
        tabs: <Widget>[
          Tab(text: strings.tabEmployees),
          Tab(text: strings.tabPositions),
          Tab(text: strings.tabContracts),
        ],
      ),
      floatingActionButton: canManage
          ? ListenableBuilder(
              listenable: _tabs.animation!,
              builder: (BuildContext context, Widget? _) {
                final int tabIndex = _tabs.index;
                final todo = switch (tabIndex) {
                  0 => (label: strings.newEmployee, onPressed: () => showEmployeeFormSheet(context)),
                  1 => (label: strings.newPosition, onPressed: () => showPositionFormSheet(context)),
                  _ => (
                    label: strings.newContract,
                    onPressed: project == null
                        ? null
                        : () => showContractFormSheet(context, projectId: project.id),
                  ),
                };
                return FloatingActionButton.extended(
                  onPressed: todo.onPressed,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(todo.label),
                );
              },
            )
          : null,
      body: TabBarView(
        controller: _tabs,
        children: const <Widget>[
          _EmployeesTab(),
          _PositionsTab(),
          _ContractsTab(),
        ],
      ),
    );
  }
}

class _EmployeesTab extends ConsumerWidget {
  const _EmployeesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Employee>> employees = ref.watch(employeesProvider);
    final Map<String, String> positions = <String, String>{
      for (final Position p
          in ref.watch(positionsProvider).valueOrNull ?? const <Position>[])
        p.id: p.name,
    };

    final AppStrings all = ref.watch(stringsProvider);
    final PersonnelStrings strings = all.personnel;

    return AsyncSection<List<Employee>>(
      value: employees,
      errorMessage: strings.employeesError,
      onRetry: () => ref.invalidate(employeesProvider),
      builder: (List<Employee> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.badge_rounded,
              title: strings.employeesEmptyTitle,
              message: strings.employeesEmptyMessage,
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async => ref.invalidate(employeesProvider),
              itemBuilder: (BuildContext context, int index) {
                final Employee e = data[index];
                final String? position = positions[e.positionId];
                return AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      LeadingIcon(
                        icon: Icons.engineering_rounded,
                        color: e.isActive
                            ? AppColors.orange
                            : AppColors.textDisabled,
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
                                    e.fullName.isEmpty ? '—' : e.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (!e.isActive)
                                  StatusChip(
                                    label: all.common.inactive,
                                    color: AppColors.textDisabled,
                                  ),
                              ],
                            ),
                            if (position != null)
                              InfoLine(
                                icon: Icons.work_outline_rounded,
                                text: position,
                              ),
                            if (e.dni.isNotEmpty)
                              InfoLine(
                                icon: Icons.badge_outlined,
                                text: strings.nationalIdOf(e.dni),
                              ),
                            if (e.phone.isNotEmpty)
                              InfoLine(
                                icon: Icons.phone_outlined,
                                text: e.phone,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PositionsTab extends ConsumerWidget {
  const _PositionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Position>> positions = ref.watch(positionsProvider);

    final PersonnelStrings strings = ref.watch(stringsProvider).personnel;

    return AsyncSection<List<Position>>(
      value: positions,
      errorMessage: strings.positionsError,
      onRetry: () => ref.invalidate(positionsProvider),
      builder: (List<Position> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.work_outline_rounded,
              title: strings.positionsEmptyTitle,
              message: strings.positionsEmptyMessage,
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async => ref.invalidate(positionsProvider),
              itemBuilder: (BuildContext context, int index) {
                final Position p = data[index];
                return AppCard(
                  child: Row(
                    children: <Widget>[
                      const LeadingIcon(
                        icon: Icons.work_outline_rounded,
                        color: AppColors.cyanNeon,
                        size: 38,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          p.name,
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
                      LabeledValue(
                        label: strings.baseSalaryUpper,
                        value: Fmt.money(p.baseSalary),
                        alignEnd: true,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  const _ContractsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ProjectScope(
    emptyMessage: ref.watch(stringsProvider).personnel.needsProject,
    builder: (BuildContext context, Project project) {
      final AsyncValue<List<LaborContract>> contracts = ref.watch(
        projectContractsProvider(project.id),
      );
      final Map<String, String> names = <String, String>{
        for (final Employee e
            in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
          e.id: e.fullName,
      };

      final PersonnelStrings strings = ref.watch(stringsProvider).personnel;

      return AsyncSection<List<LaborContract>>(
        value: contracts,
        errorMessage: strings.contractsError,
        onRetry: () => ref.invalidate(projectContractsProvider(project.id)),
        builder: (List<LaborContract> data) => data.isEmpty
            ? EmptyState(
                icon: Icons.description_outlined,
                title: strings.contractsEmptyTitle,
                message: strings.contractsEmptyFor(project.name),
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async =>
                    ref.invalidate(projectContractsProvider(project.id)),
                itemBuilder: (BuildContext context, int index) {
                  final LaborContract c = data[index];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                names[c.employeeId] ?? strings.unnamedEmployee,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            StatusChip(
                              label: c.contractType.isEmpty
                                  ? '—'
                                  : c.contractType,
                              color: AppColors.cyanNeon,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LabeledValue(
                                label: strings.salaryUpper,
                                value: Fmt.money(c.salary),
                                color: AppColors.orangeNeon,
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: strings.fromUpper,
                                value: Fmt.date(c.startDate),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: strings.toUpper,
                                value: Fmt.date(c.endDate),
                                alignEnd: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    },
  );
}
