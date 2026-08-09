import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return ModuleScaffold(
      title: 'Auditoría',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(auditLogsProvider),
      body: AsyncSection<List<AuditLog>>(
        value: logs,
        errorMessage: 'No se pudo cargar el registro de auditoría.',
        onRetry: () => ref.invalidate(auditLogsProvider),
        builder: (List<AuditLog> data) => data.isEmpty
            ? const EmptyState(
                icon: Icons.fact_check_rounded,
                title: 'Sin movimientos registrados',
                message:
                    'Aquí queda constancia de quién crea, modifica o elimina '
                    'información en el sistema.',
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

class _LogCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = _look;
    final int changed = log.newValues.length;

    return AppCard(
      child: Row(
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
                if (changed > 0)
                  InfoLine(
                    icon: Icons.data_object_rounded,
                    text:
                        '$changed campo${changed == 1 ? '' : 's'} con valor '
                        'nuevo',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
