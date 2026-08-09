import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/domain/permissions.dart';
import '../../application/notifications_providers.dart';
import 'notifications_panel.dart';

/// Campana de avisos, presente en la cabecera del panel y en la barra de todos
/// los módulos.
///
/// Solo pinta el distintivo: quien mantiene viva la bandeja y la conexión con
/// `/notifications/ws` es [NotificationsSync], montado en la raíz de la app.
/// Así el contador es el mismo en todas las pantallas y no se reconecta el
/// socket cada vez que se navega.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);
    // Sin permiso no hay campana: la bandeja tampoco se pide.
    if (user == null || !user.can(Perm.notificationsRead)) {
      return const SizedBox.shrink();
    }

    final AppStrings strings = ref.watch(stringsProvider);
    final int unread = ref.watch(unreadNotificationsProvider);

    return IconButton(
      tooltip: unread == 0 ? strings.notices : strings.unreadNotices(unread),
      color: AppColors.textSecondary,
      onPressed: () => showNotificationsPanel(context),
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
