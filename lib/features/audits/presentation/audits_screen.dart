import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/locale_controller.dart';
import '../../../core/i18n/sections/admin_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/audits_providers.dart';
import '../domain/audit_log.dart';

/// Registro de auditoría (`GET /audits-logs`).
class AuditsScreen extends ConsumerWidget {
  const AuditsScreen({super.key});

  static const String routeName = 'audits';
  static const String routePath = '/audits';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AuditLog>> logs = ref.watch(auditLogsProvider);
    final AuditsStrings strings = ref.watch(stringsProvider).audits;

    return ModuleScaffold(
      title: 'Auditoría',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(auditLogsProvider),
      body: AsyncSection<List<AuditLog>>(
        value: logs,
        errorMessage: strings.loadError,
        onRetry: () => ref.invalidate(auditLogsProvider),
        builder: (List<AuditLog> data) => data.isEmpty
            ? EmptyState(
                icon: Icons.fact_check_rounded,
                title: strings.emptyTitle,
                message: strings.emptyMessage,
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async => ref.invalidate(auditLogsProvider),
                itemBuilder: (BuildContext context, int index) =>
                    _LogCard(log: data[index]),
              ),
      ),
    );
  }
}

class _LogCard extends ConsumerWidget {
  const _LogCard({required this.log});

  final AuditLog log;

  /// Color e icono según la acción, para poder barrer la lista de un vistazo.
  (Color, IconData) get _look => switch (log.action.toUpperCase()) {
    'INSERT' || 'CREATE' => (AppColors.success, Icons.add_circle_outline),
    'UPDATE' => (AppColors.warning, Icons.edit_outlined),
    'DELETE' => (AppColors.danger, Icons.remove_circle_outline),
    _ => (AppColors.textSecondary, Icons.history_rounded),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (Color color, IconData icon) = _look;
    final AuditsStrings strings = ref.watch(stringsProvider).audits;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LeadingIcon(icon: icon, color: color, size: 38),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            log.tableName.isEmpty ? '—' : log.tableName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip(
                          label: log.action.isEmpty ? '—' : log.action,
                          color: color,
                        ),
                      ],
                    ),
                    InfoLine(
                      icon: Icons.schedule_rounded,
                      text: Fmt.dateTime(log.createdAt),
                    ),
                    if (log.ipAddress.isNotEmpty)
                      InfoLine(icon: Icons.router_outlined, text: log.ipAddress),
                  ],
                ),
              ),
            ],
          ),
          _CompareBlock(log: log, color: color, strings: strings),
        ],
      ),
    );
  }
}

/// Mini cuadro de «antes → después» con los valores que cambió la acción.
class _CompareBlock extends StatelessWidget {
  const _CompareBlock({
    required this.log,
    required this.color,
    required this.strings,
  });

  final AuditLog log;
  final Color color;
  final AuditsStrings strings;

  @override
  Widget build(BuildContext context) {
    final String action = log.action.toUpperCase();
    final List<(String, Object?)> rows = switch (action) {
      'INSERT' || 'CREATE' => [
        for (final MapEntry<String, dynamic> e in log.newValues.entries)
          (e.key, e.value),
      ],
      'DELETE' => [
        for (final MapEntry<String, dynamic> e in log.oldValues.entries)
          (e.key, e.value),
      ],
      'UPDATE' => [
        for (final String key in log.oldValues.keys)
          if (!_same(log.oldValues[key], log.newValues[key]))
            (key, log.newValues[key]),
      ],
      _ => const <(String, Object?)>[],
    };

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          strings.noFields,
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
        ),
      );
    }

    // Solo las primeras tres filas: es un vistazo, el resto se resume.
    final int shown = rows.length > 3 ? 3 : rows.length;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < shown; i++)
            _fieldRow(rows[i], action, i == 0),
          if (rows.length > shown)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                strings.more(rows.length - shown),
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fieldRow((String, Object?) row, String action, bool first) {
    final (String label, Object? value) = row;
    final Color valueColor = action == 'DELETE'
        ? AppColors.danger
        : (action == 'UPDATE' ? AppColors.warning : AppColors.success);

    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            _display(value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static bool _same(Object? a, Object? b) {
    if (a == b) return true;
    return _display(a) == _display(b);
  }

  static String _display(Object? value) {
    if (value == null) return '—';
    if (value is bool) return value.toString();
    if (value is List || value is Map) return jsonEncode(value);
    return value.toString();
  }
}
