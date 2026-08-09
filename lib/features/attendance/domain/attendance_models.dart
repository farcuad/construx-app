import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Estados de asistencia admitidos por la API.
enum AttendanceStatus {
  present('Present', 'Presente'),
  absent('Absent', 'Ausente'),
  late('Late', 'Tarde'),
  justifiedAbsence('Justified Absence', 'Falta justificada');

  const AttendanceStatus(this.apiValue, this.label);

  /// Valor exacto que espera el campo `status`.
  final String apiValue;
  final String label;

  static AttendanceStatus fromApi(String? raw) => values.firstWhere(
    (AttendanceStatus s) => s.apiValue == raw,
    orElse: () => present,
  );
}

/// Marca de asistencia de un empleado en una jornada.
@immutable
class AttendanceLog {
  const AttendanceLog({
    required this.employeeId,
    this.id = '',
    this.status = AttendanceStatus.present,
    this.hoursWorked = 0,
    this.notes = '',
  });

  final String id;
  final String employeeId;
  final AttendanceStatus status;
  final double hoursWorked;
  final String notes;

  factory AttendanceLog.fromJson(Map<String, dynamic> json) => AttendanceLog(
    id: J.str(json['id']),
    employeeId: J.str(json['employee_id']),
    status: AttendanceStatus.fromApi(J.strOrNull(json['status'])),
    hoursWorked: J.dbl(json['hours_worked']),
    notes: J.str(json['notes']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'employee_id': employeeId,
    'status': status.apiValue,
    'hours_worked': hoursWorked,
    'notes': notes,
  };
}

/// Asistencia diaria de un proyecto (`/attendance`).
@immutable
class Attendance {
  const Attendance({
    required this.projectId,
    required this.date,
    this.id = '',
    this.logs = const <AttendanceLog>[],
  });

  final String id;
  final String projectId;

  /// Campo solo-fecha (`YYYY-MM-DD`).
  final DateTime date;
  final List<AttendanceLog> logs;

  /// Cuántos trabajadores estuvieron presentes o llegaron tarde.
  int get presentCount => logs
      .where(
        (AttendanceLog l) =>
            l.status == AttendanceStatus.present ||
            l.status == AttendanceStatus.late,
      )
      .length;

  /// Horas sumadas de la jornada.
  double get totalHours =>
      logs.fold<double>(0, (double sum, AttendanceLog l) => sum + l.hoursWorked);

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    date: Fmt.parseDate(json['date']) ?? DateTime.now(),
    logs: J.list(json['logs'], AttendanceLog.fromJson),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'date': Fmt.apiDate(date),
    'logs': logs
        .map((AttendanceLog l) => l.toRequestBody())
        .toList(growable: false),
  };
}
