import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/domain/permissions.dart';
import '../../application/notifications_providers.dart';
import '../../domain/notification_models.dart';
import 'notifications_panel.dart';

/// Mantiene los avisos al día durante toda la sesión.
///
/// Se monta una sola vez, por encima del router, y hace tres cosas: sostener la
/// conexión con `/notifications/ws`, refrescar la bandeja con cada aviso que
/// llega y sacar ese aviso a la bandeja del teléfono. Antes lo hacía la
/// campana, y como la campana se desmonta al navegar, el socket se cerraba y se
/// volvía a abrir en cada pantalla.
///
/// Usa `ref.listen` y no `ref.watch` a propósito: `listen` basta para que los
/// providers no se auto-descarten, pero no reconstruye este widget —y con él
/// toda la app— cada vez que cambia la bandeja.
class NotificationsSync extends ConsumerStatefulWidget {
  const NotificationsSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationsSync> createState() => _NotificationsSyncState();
}

class _NotificationsSyncState extends ConsumerState<NotificationsSync> {
  @override
  void initState() {
    super.initState();
    // Fuera del `build`: pedir el permiso de notificaciones abre un diálogo del
    // sistema, y eso no se dispara durante la fase de montaje.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(localNotifierProvider).initialize(onOpened: _openPanel);
    });
  }

  /// Abre el panel de avisos al tocar la notificación del sistema.
  ///
  /// No se usa el id que viaja en la carga: el panel los muestra todos, y
  /// llevar a uno concreto obligaría a inventar una ruta por aviso. El
  /// contexto sale del navegador raíz porque aquí quien llama es el plugin,
  /// desde fuera del árbol de widgets.
  void _openPanel(String? payload) {
    final BuildContext? context = rootNavigatorKey.currentContext;
    if (context == null) return;
    showNotificationsPanel(context);
  }

  @override
  Widget build(BuildContext context) {
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
        final AppNotification? notice = next.valueOrNull;
        if (notice == null) return;
        ref.invalidate(notificationsInboxProvider);
        _notify(notice);
      });
    }

    return widget.child;
  }

  /// Saca el aviso a la bandeja del sistema, con el canal en el idioma activo.
  void _notify(AppNotification notice) {
    final AppStrings strings = ref.read(stringsProvider);
    ref.read(localNotifierProvider).show(notice, (
      name: strings.noticeChannelName,
      description: strings.noticeChannelDescription,
    ));
  }
}
