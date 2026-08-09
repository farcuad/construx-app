import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../application/schedule_providers.dart';
import '../domain/schedule_task.dart';

/// Cronograma de la obra seleccionada (`GET /schedule/{project_id}`).
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  static const String routeName = 'schedule';
  static const String routePath = '/schedule';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Cronograma',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(projectScheduleProvider),
    body: ProjectScope(
      emptyMessage: 'El cronograma se planifica por obra.',
      builder: (BuildContext context, Project project) =>
          _ScheduleList(project: project),
    ),
  );
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ScheduleTask>> tasks = ref.watch(
      projectScheduleProvider(project.id),
    );

    return AsyncSection<List<ScheduleTask>>(
      value: tasks,
      errorMessage: 'No se pudo cargar el cronograma.',
      onRetry: () => ref.invalidate(projectScheduleProvider(project.id)),
      builder: (List<ScheduleTask> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'Sin tareas',
              message: '«${project.name}» no tiene tareas planificadas.',
            )
          : ModuleList(
              itemCount: data.length,
              onRefresh: () async =>
                  ref.invalidate(projectScheduleProvider(project.id)),
              header: _Summary(tasks: data),
              itemBuilder: (BuildContext context, int index) =>
                  _TaskCard(task: data[index]),
            ),
    );
  }
}

/// Avance global: media simple del porcentaje de todas las tareas.
class _Summary extends StatelessWidget {
  const _Summary({required this.tasks});

  final List<ScheduleTask> tasks;

  @override
  Widget build(BuildContext context) {
    final int done = tasks.where((ScheduleTask t) => t.isDone).length;
    final double average =
        tasks.fold<double>(0, (double s, ScheduleTask t) => s + t.progress) /
        tasks.length;

    return AppCard(
      glowColor: AppColors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Avance del cronograma',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusChip(
                label: Fmt.percent(average),
                color: AppColors.orangeNeon,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(percent: average, color: AppColors.orange),
          const SizedBox(height: 10),
          Text(
            '$done de ${tasks.length} tarea${tasks.length == 1 ? '' : 's'} '
            'terminada${done == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final ScheduleTask task;

  Color get _color => switch (task.status) {
    TaskStatus.done => AppColors.success,
    TaskStatus.inProgress => AppColors.orangeNeon,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    // Una tarea sin terminar cuya fecha de fin ya pasó va en rojo: es lo que
    // el jefe de obra necesita ver primero.
    final DateTime? end = task.endDate;
    final bool late =
        !task.isDone && end != null && end.isBefore(DateTime.now());
    final Color color = late ? AppColors.danger : _color;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  task.name.isEmpty ? 'Tarea' : task.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: late
                    ? 'Atrasada'
                    : (task.status.isEmpty ? '—' : task.status),
                color: color,
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 11),
          Row(
            children: <Widget>[
              Expanded(
                child: ProgressBar(percent: task.progress, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                Fmt.percent(task.progress),
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          InfoLine(
            icon: Icons.event_rounded,
            text: '${Fmt.date(task.startDate)} → ${Fmt.date(task.endDate)}',
            top: 9,
            color: late ? AppColors.danger : null,
          ),
        ],
      ),
    );
  }
}
