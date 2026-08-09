import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/queries.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../personnel/application/personnel_providers.dart';
import '../../personnel/domain/personnel_models.dart';
import '../../progress/presentation/widgets/day_selector.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/attendance_providers.dart';
import '../domain/attendance_models.dart';

/// Día del que se consulta la lista.
final StateProvider<DateTime> attendanceDayProvider = StateProvider<DateTime>(
  (Ref ref) => DateTime.now(),
);

/// Asistencia de la obra en una fecha (`GET /attendance/{project_id}?date=…`).
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  static const String routeName = 'attendance';
  static const String routePath = '/attendance';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Asistencia',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(attendanceProvider),
    body: ProjectScope(
      emptyMessage: 'La lista se pasa por obra.',
      builder: (BuildContext context, Project project) => Column(
        children: <Widget>[
          DaySelector(dayProvider: attendanceDayProvider),
          Expanded(child: _Sheet(project: project)),
        ],
      ),
    ),
  );
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

    return AsyncSection<Attendance?>(
      value: attendance,
      errorMessage: 'No se pudo cargar la asistencia.',
      onRetry: () => ref.invalidate(attendanceProvider(query)),
      builder: (Attendance? data) {
        if (data == null || data.logs.isEmpty) {
          return const EmptyState(
            icon: Icons.how_to_reg_rounded,
            title: 'Sin lista ese día',
            message: 'No se pasó lista en la fecha elegida.',
          );
        }

        return ModuleList(
          itemCount: data.logs.length,
          onRefresh: () async => ref.invalidate(attendanceProvider(query)),
          header: _Summary(attendance: data),
          itemBuilder: (BuildContext context, int index) {
            final AttendanceLog log = data.logs[index];
            final Color color = _statusColor(log.status);
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: <Widget>[
                  LeadingIcon(
                    icon: _statusIcon(log.status),
                    color: color,
                    size: 36,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          names[log.employeeId] ?? 'Empleado',
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
                      StatusChip(label: log.status.label, color: color),
                      if (log.hoursWorked > 0) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          '${_hours(log.hoursWorked)} h',
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

class _Summary extends StatelessWidget {
  const _Summary({required this.attendance});

  final Attendance attendance;

  @override
  Widget build(BuildContext context) {
    final int total = attendance.logs.length;
    final int present = attendance.presentCount;
    final double rate = total == 0 ? 0 : present / total * 100;

    return AppCard(
      glowColor: AppColors.orange,
      child: Row(
        children: <Widget>[
          Expanded(
            child: LabeledValue(
              label: 'PRESENTES',
              value: '$present de $total',
              color: present == total
                  ? AppColors.success
                  : AppColors.orangeNeon,
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: 'ASISTENCIA',
              value: '${rate.toStringAsFixed(0)}%',
            ),
          ),
          Expanded(
            child: LabeledValue(
              label: 'HORAS',
              value: _hours(attendance.totalHours),
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => AppColors.success,
  AttendanceStatus.late => AppColors.warning,
  AttendanceStatus.absent => AppColors.danger,
  AttendanceStatus.justifiedAbsence => AppColors.textSecondary,
};

IconData _statusIcon(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Icons.check_circle_outline_rounded,
  AttendanceStatus.late => Icons.schedule_rounded,
  AttendanceStatus.absent => Icons.cancel_outlined,
  AttendanceStatus.justifiedAbsence => Icons.event_busy_rounded,
};

/// Horas sin decimales cuando son enteras: «8 h», no «8.0 h».
String _hours(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
