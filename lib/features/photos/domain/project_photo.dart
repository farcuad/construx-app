import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Foto de obra (`/photos`).
///
/// La API guarda **solo metadatos**: el archivo se sube antes a un
/// almacenamiento externo y aquí viaja su URL pública.
@immutable
class ProjectPhoto {
  const ProjectPhoto({
    required this.id,
    required this.projectId,
    required this.photoUrl,
    this.taskId,
    this.dailyReportId,
    this.description = '',
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  final String id;
  final String projectId;
  final String photoUrl;
  final String? taskId;
  final String? dailyReportId;
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  /// `true` si la foto trae coordenadas para situarla en un mapa.
  bool get hasLocation => latitude != null && longitude != null;

  factory ProjectPhoto.fromJson(Map<String, dynamic> json) => ProjectPhoto(
    id: J.str(json['id']),
    projectId: J.str(json['project_id']),
    photoUrl: J.str(json['photo_url']),
    taskId: J.strOrNull(json['task_id']),
    dailyReportId: J.strOrNull(json['daily_report_id']),
    description: J.str(json['description']),
    latitude: J.dblOrNull(json['latitude']),
    longitude: J.dblOrNull(json['longitude']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  Map<String, dynamic> toRequestBody() => <String, dynamic>{
    'project_id': projectId,
    'task_id': ?taskId,
    'daily_report_id': ?dailyReportId,
    'photo_url': photoUrl,
    'description': description,
    'latitude': ?latitude,
    'longitude': ?longitude,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProjectPhoto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
