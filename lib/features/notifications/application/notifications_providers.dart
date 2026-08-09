import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/notifications_repository.dart';
import '../data/notifications_socket.dart';
import '../domain/notification_models.dart';

final Provider<NotificationsRepository> notificationsRepositoryProvider =
    Provider<NotificationsRepository>(
      (Ref ref) => NotificationsRepository(ref.watch(apiClientProvider)),
    );

/// `GET /notifications` — bandeja del usuario actual.
final AutoDisposeFutureProvider<List<AppNotification>>
notificationsInboxProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (Ref ref) => ref.watch(notificationsRepositoryProvider).fetchInbox(),
);

/// Avisos en tiempo real (`GET /notifications/ws`).
///
/// Solo se conecta si hay token; al abandonar la pantalla `autoDispose` cierra
/// el socket, para no dejar una conexión viva en segundo plano.
final AutoDisposeStreamProvider<AppNotification> notificationsStreamProvider =
    StreamProvider.autoDispose<AppNotification>((Ref ref) {
      final String? token = ref.watch(authTokenProvider);
      if (token == null || token.isEmpty) {
        return const Stream<AppNotification>.empty();
      }
      final NotificationsSocket socket = NotificationsSocket(token: token);
      ref.onDispose(socket.close);
      return socket.connect();
    });

/// Cuántos avisos quedan sin leer, para el distintivo del menú.
final AutoDisposeProvider<int> unreadNotificationsProvider =
    Provider.autoDispose<int>((Ref ref) {
      final List<AppNotification> inbox =
          ref.watch(notificationsInboxProvider).valueOrNull ??
          const <AppNotification>[];
      return inbox.where((AppNotification n) => !n.isRead).length;
    });
