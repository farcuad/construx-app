import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/queries.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/domain/permissions.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../personnel/application/personnel_providers.dart';
import '../../personnel/domain/personnel_models.dart';
import '../../progress/presentation/widgets/day_selector.dart';
import '../../projects/application/project_scope.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/attendance_providers.dart';
import '../domain/attendance_models.dart';
import 'attendance_form_sheet.dart';

/// Asistencia de la obra en una fecha (`GET /attendance/{project_id}?date=…`).
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  static const String routeName = 'attendance';
  static const String routePath = '/attendance';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);
    final AuthUser? user = ref.watch(currentUserProvider);
    final Project? project = ref.watch(activeProjectProvider);
    final DateTime day = ref.watch(attendanceDayProvider);

    // Se puede volver a pasar lista aunque el día ya tenga registros: así el
    // supervisor puede corregir o añadir entradas sin que el botón se oculte.
    final bool canMark =
        (user?.can(Perm.attendanceMark) ?? false) && project != null;

    return ModuleScaffold(
      title: 'Asistencia',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(attendanceProvider),
      floatingActionButton: canMark
          ? FloatingActionButton.extended(
              onPressed: () => showAttendanceFormSheet(
                context,
                projectId: project.id,
                date: day,
              ),
              icon: const Icon(Icons.how_to_reg_rounded),
              label: Text(strings.attendance.formTitle),
            )
          : null,
      body: ProjectScope(
        emptyMessage: strings.attendance.needsProject,
        builder: (BuildContext context, Project project) => Column(
          children: <Widget>[
            DaySelector(dayProvider: attendanceDayProvider),
            Expanded(child: _Sheet(project: project)),
          ],
        ),
      ),
    );
  }
}

class _Sheet extends ConsumerWidget {
  const _Sheet({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectDateQuery query = projectDateQuery(
      project.id,
      ref.watch(attendanceDayProvider),
    );
    final AsyncValue<Attendance?> attendance = ref.watch(
      attendanceProvider(query),
    );
    final Map<String, String> names = <String, String>{
      for (final Employee e
          in ref.watch(employeesProvider).valueOrNull ?? const <Employee>[])
        e.id: e.fullName,
    };

    final AttendanceStrings strings = ref.watch(stringsProvider).attendance;

    return AsyncSection<Attendance?>(
      value: attendance,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(attendanceProvider(query)),
      builder: (Attendance? data) {
        if (data == null || data.logs.isEmpty) {
          return EmptyState(
            icon: Icons.how_to_reg_rounded,
            title: strings.emptyTitle,
            message: strings.emptyMessage,
          );
        }

        return ModuleList(
          itemCount: data.logs.length,
          onRefresh: () async => ref.invalidate(attendanceProvider(query)),
          header: _Summary(attendance: data),
          itemBuilder: (BuildContext context, int index) {
            final AttendanceLog log = data.logs[index];
            final Color color = attendanceStatusColor(log.status);
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: <Widget>[
                  LeadingIcon(
                    icon: attendanceStatusIcon(log.status),
                    color: color,
                    size: 36,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          names[log.employeeId] ?? strings.unnamedEmployee,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (log.notes.isNotEmpty)
                          InfoLine(
                            icon: Icons.notes_rounded,
                            text: log.notes,
                            top: 4,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      StatusChip(
                        label: strings.status(
                          log.status.apiValue,
                          log.status.label,
                        ),
                        color: color,
                      ),
                      if (log.hoursWorked > 0) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '${formatHours(log.hoursWorked)} ${strings.hourSuffix}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.attendance});

  final Attendance attendance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AttendanceStrings strings = ref.watch(stringsProvider).attendance;
    final int total = attendance.logs.length;
    final int present = attendance.presentCount;
    final double rate = total == 0 ? 0 : present / total * 100;

    return AppCard(
      glowColor: AppColors.orange,
      child: Row(
        children: <Widget>[
          Expanded(
            child: LabeledValue(
              label: strings.presentUpper,
              value: strings.countOf(present, total),
              color: present == total
                  ? AppColors.success
                  : AppColors.orangeNeon,
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: strings.rateUpper,
              value: '${rate.toStringAsFixed(0)}%',
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: strings.hoursUpper,
              value: formatHours(attendance.totalHours),
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

