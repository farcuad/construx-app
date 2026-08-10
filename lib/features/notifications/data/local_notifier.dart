import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/notification_models.dart';

/// Cómo se llama el canal de avisos en los ajustes del teléfono.
typedef NotificationChannelText = ({String name, String description});

/// Publica avisos en la bandeja del sistema.
///
/// Es una interfaz para poder sustituirla en los tests: el plugin habla con
/// Android por un canal de plataforma que no existe bajo `flutter test`.
abstract interface class LocalNotifier {
  /// Prepara el plugin y pide permiso al usuario. Idempotente.
  ///
  /// [onOpened] recibe el id del aviso cuando se toca la notificación.
  Future<void> initialize({required ValueChanged<String?> onOpened});

  /// Saca [notification] a la bandeja.
  Future<void> show(AppNotification notification, NotificationChannelText text);
}

/// Notificador que no notifica.
///
/// Es el valor por defecto del provider: así ni los tests ni ningún arranque
/// sin plataforma detrás tropiezan con el canal nativo.
class SilentLocalNotifier implements LocalNotifier {
  const SilentLocalNotifier();

  @override
  Future<void> initialize({required ValueChanged<String?> onOpened}) async {}

  @override
  Future<void> show(
    AppNotification notification,
    NotificationChannelText text,
  ) async {}
}

/// Implementación real, sobre `flutter_local_notifications`.
class SystemLocalNotifier implements LocalNotifier {
  SystemLocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Un único canal para todos los avisos de obra. Separarlos por tipo dejaría
  /// al trabajador media docena de interruptores en los ajustes de Android sin
  /// que ninguno le sirva de mucho.
  static const String channelId = 'construx_notices';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize({required ValueChanged<String?> onOpened}) async {
    if (_initialized) return;
    _initialized = true;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) =>
          onOpened(response.payload),
    );

    // Android 13 y posteriores exigen pedirlo en tiempo de ejecución. En
    // versiones anteriores el método no existe y devuelve `null`, que aquí da
    // igual: si el usuario dice que no, `show` simplemente no pinta nada.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> show(
    AppNotification notification,
    NotificationChannelText text,
  ) => _plugin.show(
    id: notificationId(notification.id),
    title: notification.title,
    body: notification.message.isEmpty ? null : notification.message,
    // El id viaja como carga para poder abrir el panel al tocar el aviso.
    payload: notification.id,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        text.name,
        channelDescription: text.description,
        importance: _importanceFor(notification.priority),
        priority: _priorityFor(notification.priority),
        // Naranja de la marca en el lateral del aviso desplegado.
        color: AppColors.orange,
        icon: '@drawable/ic_notification',
      ),
    ),
  );

  /// Convierte el id del backend (un UUID) en el entero que pide Android.
  ///
  /// Se recorta al rango positivo de 32 bits porque el lado nativo lo trata
  /// como `int` de Java. Que el mismo aviso dé siempre el mismo número es lo
  /// que evita duplicados si llega dos veces por el socket.
  @visibleForTesting
  static int notificationId(String id) => id.hashCode & 0x7fffffff;

  /// Un aviso crítico debe sonar aunque el teléfono esté en silencio visual;
  /// uno informativo no merece interrumpir.
  static Importance _importanceFor(NotificationPriority priority) =>
      switch (priority) {
        NotificationPriority.critical => Importance.max,
        NotificationPriority.high => Importance.high,
        NotificationPriority.medium => Importance.defaultImportance,
        NotificationPriority.low => Importance.low,
      };

  static Priority _priorityFor(NotificationPriority priority) =>
      switch (priority) {
        NotificationPriority.critical => Priority.max,
        NotificationPriority.high => Priority.high,
        NotificationPriority.medium => Priority.defaultPriority,
        NotificationPriority.low => Priority.low,
      };
}
