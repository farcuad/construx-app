import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/json.dart';

/// Entrada del registro de auditoría (`/audits-logs`).
@immutable
class AuditLog {
  const AuditLog({
    required this.id,
    required this.action,
    required this.tableName,
    this.rowId,
    this.userId,
    this.ipAddress = '',
    this.oldValues = const <String, dynamic>{},
    this.newValues = const <String, dynamic>{},
    this.createdAt,
  });

  final String id;

  /// `CREATE`, `UPDATE`, `DELETE`…
  final String action;

  /// Tabla afectada (`budgets`, `projects`…).
  final String tableName;
  final String? rowId;
  final String? userId;

  /// La deduce el backend de `X-Forwarded-For` o de la conexión.
  final String ipAddress;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
  final DateTime? createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: J.str(json['id']),
    action: J.str(json['action']),
    tableName: J.str(json['table_name']),
    rowId: J.strOrNull(json['row_id']),
    userId: J.strOrNull(json['user_id']),
    ipAddress: J.str(json['ip_address']),
    oldValues: _map(json['old_values']),
    newValues: _map(json['new_values']),
    createdAt: Fmt.parseDate(json['created_at']),
  );

  static Map<String, dynamic> _map(Object? raw) => raw is Map<String, dynamic>
      ? raw
      : const <String, dynamic>{};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AuditLog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
