import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
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
    title: 'Tareas',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(projectScheduleProvider),
    body: ProjectScope(
      emptyMessage: ref.watch(stringsProvider).schedule.needsProject,
      builder: (BuildContext context, Project project) =>
          _ScheduleList(project: project),
    ),
  );
}

/// Agrupa las tareas por estado y pinta cada sección que no esté vacía.
class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ScheduleTask>> tasks = ref.watch(
      projectScheduleProvider(project.id),
    );
    final ScheduleStrings strings = ref.watch(stringsProvider).schedule;

    return AsyncSection<List<ScheduleTask>>(
      value: tasks,
      errorMessage: strings.loadError,
      onRetry: () => ref.invalidate(projectScheduleProvider(project.id)),
      builder: (List<ScheduleTask> data) => data.isEmpty
          ? EmptyState(
              icon: Icons.calendar_month_rounded,
              title: strings.emptyTitle,
              message: strings.emptyFor(project.name),
            )
          : _Sections(
              tasks: data,
              strings: strings,
              onRefresh: () async =>
                  ref.invalidate(projectScheduleProvider(project.id)),
            ),
    );
  }
}

/// Lista con el resumen arriba y una sección por estado.
class _Sections extends ConsumerWidget {
  const _Sections({
    required this.tasks,
    required this.strings,
    required this.onRefresh,
  });

  final List<ScheduleTask> tasks;
  final ScheduleStrings strings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<(String, List<ScheduleTask>, Color)> sections = <(
      String,
      List<ScheduleTask>,
      Color,
    )>[
      (
        strings.pendingSection,
        tasks
            .where((ScheduleTask t) => t.status == TaskStatus.pending)
            .toList(growable: false),
        AppColors.textSecondary,
      ),
      (
        strings.inProgressSection,
        tasks
            .where((ScheduleTask t) => t.status == TaskStatus.inProgress)
            .toList(growable: false),
        AppColors.orangeNeon,
      ),
      (
        strings.doneSection,
        tasks
            .where((ScheduleTask t) => t.status == TaskStatus.done || t.isDone)
            .toList(growable: false),
        AppColors.success,
      ),
    ];

    final List<Widget> body = <Widget>[
      _Summary(tasks: tasks),
      for (final (String title, List<ScheduleTask> group, Color color)
          in sections)
        if (group.isNotEmpty) ...<Widget>[
          _SectionHeader(title: title, count: group.length, color: color),
          for (final ScheduleTask task in group) _TaskCard(task: task),
        ],
    ];

    return RefreshIndicator(
      color: AppColors.orangeNeon,
      backgroundColor: AppColors.surface,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: body.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) => body[index],
      ),
    );
  }
}

/// Encabezado con color que abre cada grupo de estado.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Row(
      children: <Widget>[
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.all(Radius.circular(9)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Container(
          height: 1.5,
          width: 64,
          color: color.withValues(alpha: 0.35),
        ),
      ],
    ),
  );
}

/// Avance global: media simple del porcentaje de todas las tareas.
class _Summary extends ConsumerWidget {
  const _Summary({required this.tasks});

  final List<ScheduleTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScheduleStrings strings = ref.watch(stringsProvider).schedule;
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
              Expanded(
                child: Text(
                  strings.overallProgress,
                  style: const TextStyle(
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
            strings.progressOf(done, tasks.length),
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

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});

  final ScheduleTask task;

  Color get _color => switch (task.status) {
    TaskStatus.done => AppColors.success,
    TaskStatus.inProgress => AppColors.orangeNeon,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ScheduleStrings strings = ref.watch(stringsProvider).schedule;
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
                  task.name.isEmpty ? strings.untitled : task.name,
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
                    ? strings.late
                    : (task.status.isEmpty
                          ? '—'
                          : strings.status(task.status, task.status)),
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
