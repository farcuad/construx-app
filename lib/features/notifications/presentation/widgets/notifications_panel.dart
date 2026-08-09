import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/notifications_providers.dart';
import '../../domain/notification_models.dart';

/// Abre la bandeja de avisos como un cuadro pequeño anclado a la campana.
///
/// Es un diálogo y no una pantalla porque los avisos se consultan de pasada:
/// se miran, se marca lo leído y se vuelve a lo que se estaba haciendo, sin
/// perder la pantalla que hay debajo.
///
/// `transitionDuration` a cero: aparece en el mismo frame del toque.
Future<void> showNotificationsPanel(BuildContext context) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) =>
          const NotificationsPanel(),
    );

/// El cuadro en sí: esquina superior derecha, bajo la campana.
class NotificationsPanel extends ConsumerWidget {
  const NotificationsPanel({super.key});

  /// Alto máximo del cuadro. Con más, deja de ser un vistazo rápido.
  static const double maxHeight = 420;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.watch(stringsProvider);

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          // El hueco superior deja ver la campana que lo abrió.
          padding: const EdgeInsets.fromLTRB(12, 54, 10, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 380,
              maxHeight: maxHeight,
            ),
            child: Material(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _PanelHeader(strings: strings),
                    const Divider(height: 1),
                    Flexible(child: _PanelBody(strings: strings)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
    child: Row(
      children: <Widget>[
        const Icon(
          Icons.notifications_rounded,
          size: 18,
          color: AppColors.orangeNeon,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            strings.notices,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: strings.close,
          iconSize: 19,
          visualDensity: VisualDensity.compact,
          color: AppColors.textSecondary,
          onPressed: Navigator.of(context).pop,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _PanelBody extends ConsumerWidget {
  const _PanelBody({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> inbox = ref.watch(
      notificationsInboxProvider,
    );

    return switch (inbox) {
      AsyncData<List<AppNotification>>(:final List<AppNotification> value) =>
        value.isEmpty
            ? _Message(
                icon: Icons.notifications_none_rounded,
                title: strings.noticesEmptyTitle,
                detail: strings.noticesEmptyMessage,
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: value.length,
                separatorBuilder: (BuildContext _, int _) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (BuildContext context, int index) =>
                    _NoticeTile(notification: value[index]),
              ),
      AsyncError<List<AppNotification>>(:final Object error) => _Message(
        icon: Icons.wifi_tethering_error_rounded,
        title: strings.somethingWentWrong,
        detail: error is ApiException ? error.message : strings.noticesError,
        action: TextButton(
          onPressed: () => ref.invalidate(notificationsInboxProvider),
          child: Text(strings.retry),
        ),
      ),
      _ => const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    };
  }
}

/// Estado vacío o de error, a la escala del cuadro (el [EmptyState] de la app
/// está pensado para ocupar una pantalla entera).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 30, color: AppColors.textDisabled),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
        if (action != null) ...<Widget>[const SizedBox(height: 6), action!],
      ],
    ),
  );
}

/// Una línea de la bandeja. Tocarla la marca como leída.
class _NoticeTile extends ConsumerWidget {
  const _NoticeTile({required this.notification});

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

    return InkWell(
      // Los ya leídos no hacen nada: gastar una petición en un toque
      // accidental no aporta.
      onTap: unread ? () => _markRead(context, ref) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 14, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unread ? _priorityColor : AppColors.border,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    notification.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (notification.message.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Fmt.dateTime(notification.createdAt),
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .markAsRead(notification.id);
      ref.invalidate(notificationsInboxProvider);
    } on ApiException catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, error.message, isError: true);
      }
    }
  }
}
