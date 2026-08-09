import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/data_widgets.dart';
import '../../home/presentation/widgets/module_scaffold.dart';
import '../application/notifications_providers.dart';
import '../domain/notification_models.dart';

/// Bandeja de avisos (`GET /notifications`), al día por WebSocket.
///
/// Mientras la pantalla está abierta se escucha `/notifications/ws`: cada aviso
/// que llega refresca la bandeja, y al salir `autoDispose` cierra el socket.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String routeName = 'notifications';
  static const String routePath = '/notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppNotification>>(notificationsStreamProvider, (
      AsyncValue<AppNotification>? _,
      AsyncValue<AppNotification> next,
    ) {
      if (next.hasValue) ref.invalidate(notificationsInboxProvider);
    });

    final AsyncValue<List<AppNotification>> inbox = ref.watch(
      notificationsInboxProvider,
    );

    return ModuleScaffold(
      title: 'Avisos',
      currentPath: routePath,
      onRefresh: () => ref.invalidate(notificationsInboxProvider),
      body: AsyncSection<List<AppNotification>>(
        value: inbox,
        errorMessage: 'No se pudieron cargar los avisos.',
        onRetry: () => ref.invalidate(notificationsInboxProvider),
        builder: (List<AppNotification> data) => data.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Todo tranquilo',
                message: 'No tienes avisos pendientes.',
              )
            : ModuleList(
                itemCount: data.length,
                onRefresh: () async =>
                    ref.invalidate(notificationsInboxProvider),
                itemBuilder: (BuildContext context, int index) =>
                    _NotificationCard(notification: data[index]),
              ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  Color get _priorityColor => switch (notification.priority) {
    NotificationPriority.critical => AppColors.danger,
    NotificationPriority.high => AppColors.orangeNeon,
    NotificationPriority.medium => AppColors.cyanNeon,
    NotificationPriority.low => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool unread = !notification.isRead;

    return AppCard(
      // Tocar un aviso sin leer lo marca como leído; los ya leídos no hacen
      // nada, para no gastar una petición en un toque accidental.
      onTap: unread ? () => _markRead(context, ref) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LeadingIcon(
            icon: unread
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: unread ? _priorityColor : AppColors.textDisabled,
            size: 38,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 14.5,
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (unread) ...<Widget>[
                      const SizedBox(width: 8),
                      StatusChip(
                        label: notification.priority.label,
                        color: _priorityColor,
                      ),
                    ],
                  ],
                ),
                if (notification.message.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
                InfoLine(
                  icon: Icons.schedule_rounded,
                  text: Fmt.dateTime(notification.createdAt),
                  top: 7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    final bool ok = await runWithFeedback(
      context,
      action: () =>
          ref.read(notificationsRepositoryProvider).markAsRead(notification.id),
      successMessage: 'Aviso marcado como leído',
    );
    if (ok) ref.invalidate(notificationsInboxProvider);
  }
}
