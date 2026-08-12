import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/site_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/queries.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../../core/widgets/neon_button.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../personnel/application/personnel_providers.dart';
import '../../personnel/domain/personnel_models.dart';
import '../application/attendance_providers.dart';
import '../data/attendance_repository.dart';
import '../domain/attendance_models.dart';

/// Abre el formulario para pasar lista en [projectId].
///
/// [date] es el día que se está viendo en pantalla —normalmente hoy—, así que
/// el caso corriente es abrir, marcar las faltas y guardar sin tocar la fecha.
Future<void> showAttendanceFormSheet(
  BuildContext context, {
  required String projectId,
  required DateTime date,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (BuildContext context) =>
      _AttendanceFormSheet(projectId: projectId, date: date),
);

class _AttendanceFormSheet extends ConsumerStatefulWidget {
  const _AttendanceFormSheet({required this.projectId, required this.date});

  final String projectId;
  final DateTime date;

  @override
  ConsumerState<_AttendanceFormSheet> createState() =>
      _AttendanceFormSheetState();
}

class _AttendanceFormSheetState extends ConsumerState<_AttendanceFormSheet> {
  late DateTime _date = widget.date;

  /// Solo las marcas que el supervisor ha tocado.
  ///
  /// Lo normal es que casi todo el mundo haya venido, así que el estado por
  /// defecto —presente, jornada completa— se calcula al vuelo en vez de
  /// materializar una fila por trabajador. Cambiar las horas de jornada
  /// arrastra a todos los que nadie ha ajustado a mano.
  final Map<String, AttendanceLog> _marks = <String, AttendanceLog>{};

  double _shiftHours = 8;
  bool _isSaving = false;
  String? _error;

  /// Horas que le tocan a cada estado mientras nadie las corrija.
  double _hoursFor(AttendanceStatus status) => switch (status) {
    AttendanceStatus.present || AttendanceStatus.late => _shiftHours,
    AttendanceStatus.absent || AttendanceStatus.justifiedAbsence => 0,
  };

  AttendanceLog _markOf(String employeeId) =>
      _marks[employeeId] ??
      AttendanceLog(employeeId: employeeId, hoursWorked: _shiftHours);

  void _setStatus(String employeeId, AttendanceStatus status) {
    final AttendanceLog current = _markOf(employeeId);
    if (current.status == status) return;
    setState(() {
      _marks[employeeId] = AttendanceLog(
        employeeId: employeeId,
        status: status,
        hoursWorked: _hoursFor(status),
        notes: current.notes,
      );
    });
  }

  Future<void> _adjust(Employee employee) async {
    final AttendanceLog current = _markOf(employee.id);
    final _Adjustment? result = await showDialog<_Adjustment>(
      context: context,
      builder: (BuildContext context) =>
          _AdjustDialog(name: employee.fullName, log: current),
    );
    if (result == null || !mounted) return;
    setState(() {
      _marks[employee.id] = AttendanceLog(
        employeeId: employee.id,
        status: current.status,
        hoursWorked: result.hours,
        notes: result.notes,
      );
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      // No se pasa lista por adelantado.
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(List<Employee> staff) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final AttendanceRepository repository = ref.read(
      attendanceRepositoryProvider,
    );

    try {
      await repository.save(
        Attendance(
          projectId: widget.projectId,
          date: _date,
          logs: staff.map((Employee e) => _markOf(e.id)).toList(growable: false),
        ),
      );
      // La pantalla salta al día guardado antes de recargar, para que lo que
      // se acaba de registrar sea justo lo que aparece bajo la hoja.
      ref.read(attendanceDayProvider.notifier).state = _date;
      ref.invalidate(
        attendanceProvider(projectDateQuery(widget.projectId, _date)),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppToast(context, ref.read(stringsProvider).attendance.created);
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
    final AttendanceStrings strings = ref.watch(stringsProvider).attendance;
    final AsyncValue<List<Employee>> employees = ref.watch(employeesProvider);
    final double inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        // La plantilla puede ser larga: la hoja ocupa casi toda la pantalla y
        // la lista se desplaza dentro, en vez de crecer sin fin.
        height: (MediaQuery.sizeOf(context).height - inset) * 0.88,
        child: AsyncSection<List<Employee>>(
          value: employees,
          errorMessage: strings.employeesError,
          onRetry: () => ref.invalidate(employeesProvider),
          builder: (List<Employee> all) {
            // Quien ya no trabaja en la empresa no sale en la lista del día.
            final List<Employee> staff = all
                .where((Employee e) => e.isActive)
                .toList(growable: false);
            if (staff.isEmpty) {
              return EmptyState(
                icon: Icons.groups_rounded,
                title: strings.noEmployeesTitle,
                message: strings.noEmployeesMessage,
              );
            }
            return _body(staff, strings);
          },
        ),
      ),
    );
  }

  Widget _body(List<Employee> staff, AttendanceStrings strings) {
    int present = 0;
    for (final Employee e in staff) {
      final AttendanceStatus status = _markOf(e.id).status;
      if (status == AttendanceStatus.present ||
          status == AttendanceStatus.late) {
        present++;
      }
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SheetHeader(title: strings.formTitle, bottom: 16),
              if (_error != null) ...<Widget>[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: _isSaving ? null : _pickDate,
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixIcon: Icon(Icons.event_rounded, size: 20),
                        ),
                        child: Text(
                          Fmt.date(_date),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 124,
                    child: _ShiftHoursField(
                      initial: _shiftHours,
                      suffix: strings.hourSuffix,
                      enabled: !_isSaving,
                      onChanged: (double hours) =>
                          setState(() => _shiftHours = hours),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text(
                    strings.presentUpper,
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  StatusChip(
                    label: strings.countOf(present, staff.length),
                    color: present == staff.length
                        ? AppColors.success
                        : AppColors.orangeNeon,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: staff.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Employee employee = staff[index];
              return _EmployeeRow(
                key: ValueKey<String>(employee.id),
                name: employee.fullName,
                log: _markOf(employee.id),
                hourSuffix: strings.hourSuffix,
                enabled: !_isSaving,
                onStatus: (AttendanceStatus s) => _setStatus(employee.id, s),
                onAdjust: () => _adjust(employee),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: NeonButton(
            label: strings.submit,
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: () => _save(staff),
          ),
        ),
      ],
    );
  }
}

/// Horas que se le dan por defecto a quien vino a trabajar.
class _ShiftHoursField extends StatefulWidget {
  const _ShiftHoursField({
    required this.initial,
    required this.suffix,
    required this.enabled,
    required this.onChanged,
  });

  final double initial;
  final String suffix;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_ShiftHoursField> createState() => _ShiftHoursFieldState();
}

class _ShiftHoursFieldState extends State<_ShiftHoursField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatHours(widget.initial),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      isDense: true,
      suffixText: widget.suffix,
      prefixIcon: const Icon(Icons.schedule_rounded, size: 20),
    ),
    onChanged: (String value) {
      final double? hours = double.tryParse(value.trim().replaceAll(',', '.'));
      // Se ignora lo que no sea una jornada creíble en vez de dar error: el
      // campo está a medio escribir mientras se teclea.
      if (hours == null || hours < 0 || hours > 24) return;
      widget.onChanged(hours);
    },
  );
}

/// Fila de un trabajador: nombre, horas y los cuatro estados.
class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    required this.name,
    required this.log,
    required this.hourSuffix,
    required this.enabled,
    required this.onStatus,
    required this.onAdjust,
    super.key,
  });

  final String name;
  final AttendanceLog log;
  final String hourSuffix;
  final bool enabled;
  final ValueChanged<AttendanceStatus> onStatus;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    onTap: enabled ? onAdjust : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${formatHours(log.hoursWorked)} $hourSuffix',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppColors.textDisabled,
            ),
            const SizedBox(width: 6),
          ],
        ),
        if (log.notes.isNotEmpty)
          InfoLine(icon: Icons.notes_rounded, text: log.notes, top: 4),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (final AttendanceStatus status in AttendanceStatus.values)
              Expanded(
                child: _StatusButton(
                  status: status,
                  selected: log.status == status,
                  enabled: enabled,
                  onTap: () => onStatus(status),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _StatusButton extends ConsumerWidget {
  const _StatusButton({
    required this.status,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AttendanceStatus status;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color color = attendanceStatusColor(status);
    final String label = ref
        .watch(stringsProvider)
        .attendance
        .status(status.apiValue, status.label);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.55) : AppColors.border,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                attendanceStatusIcon(status),
                size: 17,
                color: selected ? color : AppColors.textDisabled,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : AppColors.textDisabled,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que devuelve el diálogo de ajuste.
typedef _Adjustment = ({double hours, String notes});

/// Corrige las horas y la nota de una marca concreta.
class _AdjustDialog extends ConsumerStatefulWidget {
  const _AdjustDialog({required this.name, required this.log});

  final String name;
  final AttendanceLog log;

  @override
  ConsumerState<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends ConsumerState<_AdjustDialog> {
  late final TextEditingController _hours = TextEditingController(
    text: formatHours(widget.log.hoursWorked),
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.log.notes,
  );

  @override
  void dispose() {
    _hours.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final double hours =
        double.tryParse(_hours.text.trim().replaceAll(',', '.')) ?? 0;
    Navigator.of(context).pop((
      hours: hours.clamp(0, 24).toDouble(),
      notes: _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings all = ref.watch(stringsProvider);
    final AttendanceStrings strings = all.attendance;

    return AlertDialog(
      title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _hours,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: strings.hoursLabel,
              prefixIcon: const Icon(Icons.schedule_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _notes,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: all.common.notesOptional,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(all.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(all.common.saveChanges)),
      ],
    );
  }
}

/// Color del estado. Compartido con la pantalla de consulta.
Color attendanceStatusColor(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => AppColors.success,
  AttendanceStatus.late => AppColors.warning,
  AttendanceStatus.absent => AppColors.danger,
  AttendanceStatus.justifiedAbsence => AppColors.textSecondary,
};

/// Icono del estado. Compartido con la pantalla de consulta.
IconData attendanceStatusIcon(AttendanceStatus status) => switch (status) {
  AttendanceStatus.present => Icons.check_circle_outline_rounded,
  AttendanceStatus.late => Icons.schedule_rounded,
  AttendanceStatus.absent => Icons.cancel_outlined,
  AttendanceStatus.justifiedAbsence => Icons.event_busy_rounded,
};

/// Horas sin decimales cuando son enteras: «8», no «8.0».
String formatHours(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
