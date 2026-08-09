import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Estados de una tarea del cronograma.
abstract final class TaskStatus {
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String done = 'Done';
}

/// Tarea del cronograma de obra (`/schedule/tasks`).
@immutable
class ScheduleTask {
  const ScheduleTask({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    this.startDate,
    this.endDate,
    this.progress = 0,
    this.status = TaskStatus.pending,
  });

  final String id;
  final String projectId;
  final String name;
  final String description;

  /// Campos solo-fecha (`YYYY-MM-DD`).
  final DateTime? startDate;
  final DateTime? endDate;

  /// Avance declarado, 0..100.
  final double progress;
  final String status;

  bool get isDone => status == TaskStatus.done || progress >= 100;

  factory ScheduleTask.fromJson(Map<String, dynamic> json) => ScheduleTask(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    name: J.str(json['name']),
    description: J.str(json['description']),
    startDate: Fmt.parseDate(json['start_date']),
    endDate: Fmt.parseDate(json['end_date']),
    progress: J.dbl(json['progress']),
    status: J.str(json['status']),
  );

  /// Cuerpo de `POST` y `PUT` (en el `PUT` el `id` viaja en la URL).
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'name': name,
    'description': description,
    if (startDate != null) 'start_date': Fmt.apiDate(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDate(endDate!),
    'progress': progress,
    'status': status,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScheduleTask && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
