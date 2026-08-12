import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/queries.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../schedule/application/schedule_providers.dart';
import '../../schedule/domain/schedule_task.dart';
import '../application/progress_providers.dart';
import '../data/progress_repository.dart';
import '../domain/daily_report.dart';

/// Abre el formulario del parte diario de [projectId].
///
/// [date] es el día que se está viendo, que de arranque es hoy.
Future<void> showProgressFormSheet(
  BuildContext context, {
  required String projectId,
  required DateTime date,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) =>
      _ProgressFormSheet(projectId: projectId, date: date),
);

/// Una tarea metida en el parte, con sus campos a medio escribir.
///
/// Los controladores viven aquí y no en el widget de la fila para que reordenar
/// o quitar una tarea no pierda lo tecleado en las demás.
class _EntryDraft {
  _EntryDraft({required this.task, required double percentage})
    : percent = TextEditingController(text: _trim(percentage)),
      quantity = TextEditingController(),
      notes = TextEditingController();

  final ScheduleTask task;
  final TextEditingController percent;
  final TextEditingController quantity;
  final TextEditingController notes;

  void dispose() {
    percent.dispose();
    quantity.dispose();
    notes.dispose();
  }

  static String _trim(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  double get percentValue =>
      double.tryParse(percent.text.trim().replaceAll(',', '.')) ?? 0;

  ProgressEntry toEntry() => ProgressEntry(
    taskId: task.id,
    progressPercentage: percentValue,
    quantityExecuted:
        double.tryParse(quantity.text.trim().replaceAll(',', '.')) ?? 0,
    notes: notes.text.trim(),
  );
}

class _ProgressFormSheet extends ConsumerStatefulWidget {
  const _ProgressFormSheet({required this.projectId, required this.date});

  final String projectId;
  final DateTime date;

  @override
  ConsumerState<_ProgressFormSheet> createState() => _ProgressFormSheetState();
}

class _ProgressFormSheetState extends ConsumerState<_ProgressFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _weather = TextEditingController();
  final TextEditingController _observations = TextEditingController();
  final List<_EntryDraft> _entries = <_EntryDraft>[];

  late DateTime _date = widget.date;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _weather.dispose();
    _observations.dispose();
    for (final _EntryDraft entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      // No se reporta avance de un día que no ha llegado.
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addTask(List<ScheduleTask> tasks, ProgressStrings strings) async {
    final Set<String> used = <String>{
      for (final _EntryDraft e in _entries) e.task.id,
    };
    final List<ScheduleTask> available = tasks
        .where((ScheduleTask t) => !used.contains(t.id))
        .toList(growable: false);

    if (available.isEmpty) {
      showAppToast(context, strings.allTasksAdded, kind: ToastKind.info);
      return;
    }

    final ScheduleTask? picked = await showDialog<ScheduleTask>(
      context: context,
      builder: (BuildContext context) =>
          _TaskPickerDialog(tasks: available, title: strings.addTask),
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Arranca en el avance que ya tenía la tarea: casi siempre se sube desde
      // ahí, y así no hay que volver a teclear lo que ya estaba reportado.
      _entries.add(_EntryDraft(task: picked, percentage: picked.progress));
    });
  }

  void _remove(_EntryDraft entry) {
    setState(() => _entries.remove(entry));
    entry.dispose();
  }

  Future<void> _save(ProgressStrings strings) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_entries.isEmpty) {
      setState(() => _error = strings.needsEntries);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final ProgressRepository repository = ref.read(progressRepositoryProvider);

    try {
      await repository.create(
        DailyReport(
          id: '',
          projectId: widget.projectId,
          reportDate: _date,
          weatherCondition: _weather.text.trim(),
          observations: _observations.text.trim(),
          entries: _entries
              .map((_EntryDraft e) => e.toEntry())
              .toList(growable: false),
        ),
      );
      // La pantalla salta al día del parte para que se vea recién guardado, y
      // el cronograma se recarga porque el avance de sus tareas ha cambiado.
      ref.read(progressDayProvider.notifier).state = _date;
      ref.invalidate(
        dailyReportProvider(projectDateQuery(widget.projectId, _date)),
      );
      ref.invalidate(projectScheduleProvider(widget.projectId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(context, strings.created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProgressStrings strings = ref.watch(stringsProvider).progress;
    final AsyncValue<List<ScheduleTask>> tasks = ref.watch(
      projectScheduleProvider(widget.projectId),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AsyncSection<List<ScheduleTask>>(
        value: tasks,
        errorMessage: strings.tasksError,
        onRetry: () =>
            ref.invalidate(projectScheduleProvider(widget.projectId)),
        builder: (List<ScheduleTask> list) => list.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: Icons.calendar_month_rounded,
                  title: strings.noTasksTitle,
                  message: strings.noTasksMessage,
                ),
              )
            : _body(list, strings),
      ),
    );
  }

  Widget _body(List<ScheduleTask> tasks, ProgressStrings strings) {
    final AppStrings all = ref.watch(stringsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SheetHeader(title: strings.formTitle),
            if (_error != null) ...<Widget>[
              ErrorBanner(
                message: _error!,
                onDismiss: () => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
            ],
            InkWell(
              onTap: _isSaving ? null : _pickDate,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: all.common.date,
                  prefixIcon: const Icon(Icons.event_rounded, size: 20),
                ),
                child: Text(
                  Fmt.date(_date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weather,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.weather,
                prefixIcon: const Icon(Icons.cloud_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _observations,
              enabled: !_isSaving,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: strings.observations,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                Text(
                  strings.tasksTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isSaving ? null : () => _addTask(tasks, strings),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(strings.addTask),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final _EntryDraft entry in _entries) ...<Widget>[
              _EntryCard(
                key: ValueKey<String>(entry.task.id),
                entry: entry,
                enabled: !_isSaving,
                strings: strings,
                quantityLabel: all.common.quantity,
                notesLabel: all.common.notesOptional,
                onRemove: () => _remove(entry),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            NeonButton(
              label: strings.submit,
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: () => _save(strings),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de una tarea dentro del parte.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.enabled,
    required this.strings,
    required this.quantityLabel,
    required this.notesLabel,
    required this.onRemove,
    super.key,
  });

  final _EntryDraft entry;
  final bool enabled;
  final ProgressStrings strings;
  final String quantityLabel;
  final String notesLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                entry.task.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: strings.removeTask,
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textDisabled,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: entry.percent,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) {
                  final String? base = Validators.amount(value);
                  if (base != null) return base;
                  final double parsed =
                      double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      ) ??
                      0;
                  return parsed > 100 ? strings.percentInvalid : null;
                },
                decoration: InputDecoration(
                  isDense: true,
                  labelText: strings.percentLabel,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: entry.quantity,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (String? value) =>
                    Validators.amount(value, isRequired: false),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: quantityLabel,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: entry.notes,
          enabled: enabled,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(isDense: true, labelText: notesLabel),
        ),
      ],
    ),
  );
}

/// Elige qué tarea del cronograma se añade al parte.
class _TaskPickerDialog extends StatelessWidget {
  const _TaskPickerDialog({required this.tasks, required this.title});

  final List<ScheduleTask> tasks;
  final String title;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: tasks.length,
        itemBuilder: (BuildContext context, int index) {
          final ScheduleTask task = tasks[index];
          return ListTile(
            dense: true,
            title: Text(
              task.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Text(
              Fmt.percent(task.progress),
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
            onTap: () => Navigator.of(context).pop(task),
          );
        },
      ),
    ),
  );
}
