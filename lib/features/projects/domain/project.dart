import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';

/// Obra o proyecto de construcción (`/projects`).
@immutable
class Project {
  const Project({
    required this.id,
    required this.name,
    this.clientId,
    this.location = '',
    this.startDate,
    this.endDate,
    this.budget,
    this.statusId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? clientId;
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final int? statusId;
  final DateTime? createdAt;

  /// Progreso temporal (0..1) entre [startDate] y [endDate].
  ///
  /// Es una estimación por calendario, no el avance real de obra (ese vive en
  /// el módulo de progreso).
  double? get timeProgress {
    final DateTime? start = startDate;
    final DateTime? end = endDate;
    if (start == null || end == null) return null;
    final int total = end.difference(start).inMinutes;
    if (total <= 0) return null;
    final int elapsed = DateTime.now().difference(start).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    clientId: json['client_id'] as String?,
    location: json['location'] as String? ?? '',
    startDate: Fmt.parseDate(json['start_date']),
    endDate: Fmt.parseDate(json['end_date']),
    budget: Fmt.parseNum(json['budget']),
    statusId: (json['status_id'] as num?)?.toInt(),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  /// Cuerpo para `POST /projects` y `PUT /projects/{id}`.
  ///
  /// Las fechas van en RFC 3339 tal y como documenta la API; los campos
  /// vacíos se omiten para no sobreescribir datos con `null` en el `PUT`.
  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'name': name,
    if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
    'location': location,
    if (startDate != null) 'start_date': Fmt.apiDateTime(startDate!),
    if (endDate != null) 'end_date': Fmt.apiDateTime(endDate!),
    'budget': ?budget,
  };

  Project copyWith({
    String? name,
    String? clientId,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
  }) => Project(
    id: id,
    name: name ?? this.name,
    clientId: clientId ?? this.clientId,
    location: location ?? this.location,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    budget: budget ?? this.budget,
    statusId: statusId,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Project && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
