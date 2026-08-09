import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/personnel_providers.dart';
import '../domain/personnel_models.dart';

/// Personal de la empresa: empleados, cargos y contratos laborales por obra.
class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  static const String routeName = 'personnel';
  static const String routePath = '/personnel';

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 3,
    child: ModuleScaffold(
      title: 'Personal',
      currentPath: routePath,
      onRefresh: () {
        ref.invalidate(employeesProvider);
        ref.invalidate(positionsProvider);
        ref.invalidate(projectContractsProvider);
      },
      bottom: const TabBar(
        tabs: <Widget>[
          Tab(text: 'Empleados'),
          Tab(text: 'Cargos'),
          Tab(text: 'Contratos'),
        ],
      ),
      body: const TabBarView(
        children: <Widget>[_EmployeesTab(), _PositionsTab(), _ContractsTab()],
      ),
    ),
  );
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

    return AsyncSection<List<Employee>>(
      value: employees,
      errorMessage: 'No se pudo cargar la plantilla.',
      onRetry: () => ref.invalidate(employeesProvider),
      builder: (List<Employee> data) => data.isEmpty
          ? const EmptyState(
              icon: Icons.badge_rounded,
              title: 'Sin empleados',
              message: 'Aquí aparecerá la plantilla de la empresa.',
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
                                  const StatusChip(
                                    label: 'Inactivo',
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
                                text: 'DNI ${e.dni}',
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

    return AsyncSection<List<Position>>(
      value: positions,
      errorMessage: 'No se pudieron cargar los cargos.',
      onRetry: () => ref.invalidate(positionsProvider),
      builder: (List<Position> data) => data.isEmpty
          ? const EmptyState(
              icon: Icons.work_outline_rounded,
              title: 'Sin cargos',
              message: 'Los cargos definen el salario base de cada puesto.',
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
                        label: 'SALARIO BASE',
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
    emptyMessage: 'Los contratos laborales se asignan a una obra.',
    builder: (BuildContext context, Project project) {
      final AsyncValue<List<LaborContract>> contracts = ref.watch(
        projectContractsProvider(project.id),
      );
      final Map<String, String> names = <String, String>{
        for (final Employee e
            in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
          e.id: e.fullName,
      };

      return AsyncSection<List<LaborContract>>(
        value: contracts,
        errorMessage: 'No se pudieron cargar los contratos.',
        onRetry: () => ref.invalidate(projectContractsProvider(project.id)),
        builder: (List<LaborContract> data) => data.isEmpty
            ? EmptyState(
                icon: Icons.description_outlined,
                title: 'Sin contratos',
                message: 'Nadie tiene contrato asignado a «${project.name}».',
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
                                names[c.employeeId] ?? 'Empleado',
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
                                label: 'SALARIO',
                                value: Fmt.money(c.salary),
                                color: AppColors.orangeNeon,
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: 'DESDE',
                                value: Fmt.date(c.startDate),
                              ),
                            ),
                            Expanded(
                              child: LabeledValue(
                                label: 'HASTA',
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
