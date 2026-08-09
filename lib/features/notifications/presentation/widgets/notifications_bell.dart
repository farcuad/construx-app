import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/domain/permissions.dart';
import '../../application/notifications_providers.dart';
import '../../domain/notification_models.dart';
import '../notifications_screen.dart';

/// Campana de avisos para la cabecera del panel.
///
/// Mientras está montada mantiene abierta la conexión con `/notifications/ws`:
/// cada aviso que llega refresca la bandeja y, con ella, el número del
/// distintivo. Al salir del panel `autoDispose` cierra el socket, que es lo que
/// se quiere — no tiene sentido sostener una conexión desde una pantalla que
/// no la usa.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    // Sin permiso no se pide la bandeja: sería un 403 en cada arranque.
    if (user == null || !user.can(Perm.notificationsRead)) {
      return const SizedBox.shrink();
    }

    ref.listen<AsyncValue<AppNotification>>(notificationsStreamProvider, (
      AsyncValue<AppNotification>? _,
      AsyncValue<AppNotification> next,
    ) {
      if (next.hasValue) ref.invalidate(notificationsInboxProvider);
    });

    final int unread = ref.watch(unreadNotificationsProvider);

    return IconButton(
      tooltip: unread == 0
          ? 'Avisos'
          : '$unread aviso${unread == 1 ? '' : 's'} sin leer',
      color: AppColors.textSecondary,
      onPressed: () => context.go(NotificationsScreen.routePath),
      icon: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Icon(
            unread == 0
                ? Icons.notifications_none_rounded
                : Icons.notifications_active_rounded,
            color: unread == 0 ? AppColors.textSecondary : AppColors.orangeNeon,
          ),
          if (unread > 0)
            Positioned(right: -4, top: -3, child: _Badge(count: unread)),
        ],
      ),
    );
  }
}

/// Contador de no leídos. Por encima de 9 se muestra «9+» para que el
/// distintivo no crezca y descoloque el icono.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    constraints: const BoxConstraints(minWidth: 16),
    height: 16,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.danger,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      // Un borde del color del fondo separa el distintivo del icono cuando se
      // solapan, sin necesidad de dejar hueco.
      border: Border.all(color: AppColors.background, width: 1.5),
    ),
    child: Text(
      count > 9 ? '9+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
  );
}
