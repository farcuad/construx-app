import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/domain/permissions.dart';
import '../../application/notifications_providers.dart';
import '../../domain/notification_models.dart';

/// Mantiene los avisos al día durante toda la sesión.
///
/// Se monta una sola vez, por encima del router, y hace dos cosas: sostener la
/// conexión con `/notifications/ws` y refrescar la bandeja con cada aviso que
/// llega. Antes lo hacía la campana, y como la campana se desmonta al navegar,
/// el socket se cerraba y se volvía a abrir en cada pantalla.
///
/// Usa `ref.listen` y no `ref.watch` a propósito: `listen` basta para que los
/// providers no se auto-descarten, pero no reconstruye este widget —y con él
/// toda la app— cada vez que cambia la bandeja.
class NotificationsSync extends ConsumerWidget {
  const NotificationsSync({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? user = ref.watch(currentUserProvider);

    // Sin sesión o sin permiso no se abre socket ni se pide la bandeja: sería
    // un 403 en cada arranque.
    if (user != null && user.can(Perm.notificationsRead)) {
      ref.listen<AsyncValue<List<AppNotification>>>(
        notificationsInboxProvider,
        (_, _) {},
      );
      ref.listen<AsyncValue<AppNotification>>(notificationsStreamProvider, (
        AsyncValue<AppNotification>? _,
        AsyncValue<AppNotification> next,
      ) {
        if (next.hasValue) ref.invalidate(notificationsInboxProvider);
      });
    }

    return child;
  }
}
