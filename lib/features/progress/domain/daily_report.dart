import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Avance declarado de una tarea dentro de un reporte diario.
@immutable
class ProgressEntry {
  const ProgressEntry({
    required this.taskId,
    this.progressPercentage = 0,
    this.quantityExecuted = 0,
    this.notes = '',
  });

  final String taskId;

  /// Avance de la tarea, 0..100.
  final double progressPercentage;

  /// Cantidad ejecutada en la unidad de la tarea (m², m³…).
  final double quantityExecuted;
  final String notes;

  factory ProgressEntry.fromJson(Map<String, dynamic> json) => ProgressEntry(
    taskId: J.str(json['task_id']),
    progressPercentage: J.dbl(json['progress_percentage']),
    quantityExecuted: J.dbl(json['quantity_executed']),
    notes: J.str(json['notes']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'task_id': taskId,
    'progress_percentage': progressPercentage,
    'quantity_executed': quantityExecuted,
    'notes': notes,
  };
}

/// Reporte diario de obra (`/progress/daily`).
@immutable
class DailyReport {
  const DailyReport({
    required this.id,
    required this.projectId,
    required this.reportDate,
    this.weatherCondition = '',
    this.observations = '',
    this.entries = const <ProgressEntry>[],
  });

  final String id;
  final String projectId;

  /// A diferencia de otras fechas del API, esta va en RFC 3339.
  final DateTime reportDate;
  final String weatherCondition;
  final String observations;
  final List<ProgressEntry> entries;

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    reportDate: Fmt.parseDate(json['report_date']) ?? DateTime.now(),
    weatherCondition: J.str(json['weather_condition']),
    observations: J.str(json['observations']),
    entries: J.list(json['progress_entries'], ProgressEntry.fromJson),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'report_date': Fmt.apiDateTime(reportDate),
    'weather_condition': weatherCondition,
    'observations': observations,
    'progress_entries': entries
        .map((ProgressEntry e) => e.toRequestBody())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DailyReport && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
