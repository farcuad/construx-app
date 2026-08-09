import '../../../core/network/api_client.dart';
import '../domain/notification_models.dart';

/// Bandeja de notificaciones (`/notifications`).
///
/// Estas rutas son `protectedBasic`: piden token y permiso, pero **no**
/// comprueban la suscripción, así que siguen funcionando aunque el plan de la
/// empresa haya caducado.
class NotificationsRepository {
  const NotificationsRepository(this._api);

  final ApiClient _api;

  /// `GET /notifications` — bandeja del usuario del token.
  Future<List<AppNotification>> fetchInbox() async =>
      (await _api.getList('/notifications'))
          .map(AppNotification.fromJson)
          .toList(growable: false);

  /// `POST /notifications` — crea el aviso para [targetUsers].
  Future<AppNotification> create(
    AppNotification notification, {
    required List<String> targetUsers,
  }) async => AppNotification.fromJson(
    await _api.post(
      '/notifications',
      body: notification.toRequestBody(targetUsers),
    ),
  );

  /// `PATCH /notifications/{id}/read`.
  Future<void> markAsRead(String id) => _api.patch('/notifications/$id/read');

  /// `DELETE /notifications/{id}`.
  Future<void> delete(String id) => _api.delete('/notifications/$id');
}
