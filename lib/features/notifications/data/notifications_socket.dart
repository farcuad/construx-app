import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/app_config.dart';
import '../domain/notification_models.dart';

/// Canal en tiempo real de notificaciones (`GET /notifications/ws`).
///
/// El backend levanta la conexión con Gorilla y registra al usuario en su hub.
/// Como el handshake de un WebSocket no admite cabeceras propias en todas las
/// plataformas, el token viaja en el query param `?token=`, que la API acepta
/// como alternativa a `Authorization`.
class NotificationsSocket {
  NotificationsSocket({required this.token, String? baseUrl})
    : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String token;
  final String baseUrl;

  WebSocketChannel? _channel;

  /// URL del socket: el `http(s)` de la API pasa a `ws(s)`.
  Uri get uri {
    final Uri base = Uri.parse(baseUrl);
    return base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: '${base.path}/notifications/ws',
      queryParameters: <String, String>{'token': token},
    );
  }

  /// Abre la conexión y emite cada aviso que llega.
  ///
  /// Los mensajes que no sean un JSON de notificación se descartan en lugar de
  /// romper el stream: un `ping` del servidor no debe tumbar la bandeja.
  Stream<AppNotification> connect() {
    final WebSocketChannel channel = WebSocketChannel.connect(uri);
    _channel = channel;
    return channel.stream
        .map(_tryParse)
        .where((AppNotification? n) => n != null)
        .cast<AppNotification>();
  }

  static AppNotification? _tryParse(Object? message) {
    if (message is! String) return null;
    try {
      final Object? decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return null;
      return AppNotification.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  /// Cierra la conexión. Es idempotente.
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
