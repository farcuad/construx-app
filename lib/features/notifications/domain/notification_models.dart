import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Prioridad de una notificación.
enum NotificationPriority {
  low('low', 'Baja'),
  medium('medium', 'Media'),
  high('high', 'Alta'),
  critical('critical', 'Crítica');

  const NotificationPriority(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static NotificationPriority fromApi(String? raw) => values.firstWhere(
    (NotificationPriority p) => p.apiValue == raw,
    orElse: () => medium,
  );
}

/// Aviso dirigido a uno o varios usuarios (`/notifications`).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.message = '',
    this.type = 'info',
    this.priority = NotificationPriority.medium,
    this.projectId,
    this.entityType,
    this.entityId,
    this.linkToUi,
    this.metadata = const <String, dynamic>{},
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final NotificationPriority priority;
  final String? projectId;

  /// Qué entidad originó el aviso (`project`, `budget`…).
  final String? entityType;
  final String? entityId;

  /// Ruta interna a la que debería llevar el aviso al tocarlo.
  final String? linkToUi;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: J.str(json['id']),
        title: J.str(json['title']),
        message: J.str(json['message']),
        type: J.str(json['type']),
        priority: NotificationPriority.fromApi(J.strOrNull(json['priority'])),
        projectId: J.strOrNull(json['project_id']),
        entityType: J.strOrNull(json['entity_type']),
        entityId: J.strOrNull(json['entity_id']),
        linkToUi: J.strOrNull(json['link_to_ui']),
        metadata: json['metadata'] is Map<String, dynamic>
            ? json['metadata'] as Map<String, dynamic>
            : const <String, dynamic>{},
        isRead: J.boolOf(json['is_read']),
        createdAt: Fmt.parseDate(json['created_at']),
      );

  /// Cuerpo de `POST /notifications`. [targetUsers] son los destinatarios.
  Map<String, dynamic> toRequestBody(List<String> targetUsers) =>
      <String, dynamic>{
        'project_id': ?projectId,
        'entity_type': ?entityType,
        'entity_id': ?entityId,
        'type': type,
        'priority': priority.apiValue,
        'title': title,
        'message': message,
        'link_to_ui': ?linkToUi,
        if (metadata.isNotEmpty) 'metadata': metadata,
        'target_users': targetUsers,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppNotification && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
