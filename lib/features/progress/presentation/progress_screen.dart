import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/queries.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/widgets/project_selector.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_task.dart';
import '../application/progress_providers.dart';
import '../domain/daily_report.dart';
import 'widgets/day_selector.dart';

/// Día del reporte que se está consultando.
final StateProvider<DateTime> progressDayProvider = StateProvider<DateTime>(
  (Ref ref) => DateTime.now(),
);

/// Reporte diario de avance (`GET /progress/{project_id}?date=…`).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const String routeName = 'progress';
  static const String routePath = '/progress';

  @override
  Widget build(BuildContext context, WidgetRef ref) => ModuleScaffold(
    title: 'Avance de obra',
    currentPath: routePath,
    onRefresh: () => ref.invalidate(dailyReportProvider),
    body: ProjectScope(
      emptyMessage: 'El avance se reporta por obra.',
      builder: (BuildContext context, Project project) => Column(
        children: <Widget>[
          DaySelector(dayProvider: progressDayProvider),
          Expanded(child: _Report(project: project)),
        ],
      ),
    ),
  );
}

class _Report extends ConsumerWidget {
  const _Report({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectDateQuery query = projectDateQuery(
      project.id,
      ref.watch(progressDayProvider),
    );
    final AsyncValue<DailyReport?> report = ref.watch(
      dailyReportProvider(query),
    );
    final Map<String, String> taskNames = <String, String>{
      for (final ScheduleTask t
          in ref.watch(projectScheduleProvider(project.id)).valueOrNull ??
              const <ScheduleTask>[])
        t.id: t.name,
    };

    return AsyncSection<DailyReport?>(
      value: report,
      errorMessage: 'No se pudo cargar el reporte del día.',
      onRetry: () => ref.invalidate(dailyReportProvider(query)),
      builder: (DailyReport? data) {
        if (data == null) {
          return const EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Sin reporte ese día',
            message:
                'No se registró avance en la fecha elegida. Prueba con otro '
                'día.',
          );
        }

        return ModuleList(
          itemCount: data.entries.length,
          onRefresh: () async => ref.invalidate(dailyReportProvider(query)),
          header: _Header(report: data),
          itemBuilder: (BuildContext context, int index) {
            final ProgressEntry entry = data.entries[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    taskNames[entry.taskId] ?? 'Tarea',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ProgressBar(
                          percent: entry.progressPercentage,
                          color: AppColors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Fmt.percent(entry.progressPercentage),
                        style: const TextStyle(
                          color: AppColors.orangeNeon,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (entry.quantityExecuted > 0)
                    InfoLine(
                      icon: Icons.straighten_rounded,
                      text: 'Ejecutado: ${entry.quantityExecuted}',
                      top: 8,
                    ),
                  if (entry.notes.isNotEmpty)
                    InfoLine(icon: Icons.notes_rounded, text: entry.notes),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report});

  final DailyReport report;

  @override
  Widget build(BuildContext context) => AppCard(
    glowColor: AppColors.orange,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const LeadingIcon(
              icon: Icons.trending_up_rounded,
              color: AppColors.orange,
              size: 38,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: LabeledValue(
                label: 'REPORTE DEL DÍA',
                value: Fmt.date(report.reportDate),
              ),
            ),
            if (report.weatherCondition.isNotEmpty)
              StatusChip(
                label: report.weatherCondition,
                color: AppColors.cyanNeon,
              ),
          ],
        ),
        if (report.observations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            report.observations,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ],
    ),
  );
}
