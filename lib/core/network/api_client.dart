import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

/// Devuelve el token JWT vigente, o `null` si no hay sesión.
typedef TokenProvider = String? Function();

/// Se invoca cuando el backend responde 401 con un token que creíamos válido,
/// para que la app cierre la sesión y vuelva al login.
typedef UnauthorizedCallback = void Function();

/// Cliente HTTP de la aplicación.
///
/// Responsabilidades:
/// * componer la URL a partir de [AppConfig.apiBaseUrl] (la API **no** usa
///   prefijo `/api`: los endpoints cuelgan directo del host);
/// * inyectar `Authorization: Bearer <token>` cuando hay sesión;
/// * decodificar JSON y normalizar todos los errores a [ApiException].
///
/// Reutiliza una única [http.Client] para aprovechar el *keep-alive* de las
/// conexiones; llama a [close] al terminar.
class ApiClient {
  /// [baseUrl] a `null` toma la del `.env` ([AppConfig.apiBaseUrl]). No puede
  /// ser el valor por defecto del parámetro porque ya no es una constante:
  /// se resuelve en tiempo de ejecución, al cargar el `.env`.
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    this.tokenProvider,
    this.onUnauthorized,
    this.timeout = AppConfig.requestTimeout,
  }) : _baseUrl = _trimSlash(baseUrl ?? AppConfig.apiBaseUrl),
       _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  final String _baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  /// Fuente del JWT. Se consulta en cada petición para que un `login`/`logout`
  /// se refleje sin reconstruir el cliente.
  final TokenProvider? tokenProvider;

  /// Notificación de sesión caducada.
  final UnauthorizedCallback? onUnauthorized;

  /// Timeout aplicado a cada petición.
  final Duration timeout;

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// `GET` que devuelve un objeto JSON.
  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async => _asObject(
    await _send('GET', path, query: query, authenticated: authenticated),
  );

  /// `GET` que devuelve una lista JSON.
  ///
  /// El backend responde `null` en lugar de `[]` cuando no hay filas, así que
  /// se normaliza a lista vacía.
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async => _asList(
    await _send('GET', path, query: query, authenticated: authenticated),
  );

  /// `POST` que devuelve un objeto JSON.
  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async => _asObject(
    await _send(
      'POST',
      path,
      body: body,
      query: query,
      authenticated: authenticated,
    ),
  );

  /// `PUT` que devuelve un objeto JSON.
  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async => _asObject(
    await _send('PUT', path, body: body, authenticated: authenticated),
  );

  /// `PATCH` que devuelve un objeto JSON.
  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) async => _asObject(
    await _send('PATCH', path, body: body, authenticated: authenticated),
  );

  /// `DELETE`. Varios endpoints responden `204 No Content`, por eso no se
  /// exige cuerpo en la respuesta.
  Future<void> delete(String path, {bool authenticated = true}) async {
    await _send('DELETE', path, authenticated: authenticated);
  }

  /// Libera la conexión subyacente si este cliente la creó.
  void close() {
    if (_ownsClient) _client.close();
  }

  // ── Interno ─────────────────────────────────────────────────────────────

  Uri _uri(String path, Map<String, dynamic>? query) {
    final String normalized = path.startsWith('/') ? path : '/$path';
    final Uri uri = Uri.parse('$_baseUrl$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: <String, String>{
        for (final MapEntry<String, dynamic> e in query.entries)
          if (e.value != null) e.key: '${e.value}',
      },
    );
  }

  Map<String, String> _headers({
    required bool authenticated,
    bool hasBody = false,
  }) {
    final Map<String, String> headers = <String, String>{
      'Accept': _jsonHeaders['Accept']!,
      if (hasBody) 'Content-Type': _jsonHeaders['Content-Type']!,
    };
    if (authenticated) {
      final String? token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Ejecuta la petición y devuelve el JSON decodificado (`null` si 204).
  Future<Object?> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required bool authenticated,
  }) async {
    final Uri uri = _uri(path, query);
    final bool hasBody = body != null;
    final http.Request request = http.Request(
      method,
      uri,
    )..headers.addAll(_headers(authenticated: authenticated, hasBody: hasBody));
    if (hasBody) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const NetworkException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const NetworkException();
    } on Object {
      // SocketException, HandshakeException… no se importa dart:io para
      // mantener el cliente compatible con web y con los tests.
      throw const NetworkException();
    }

    return _decode(response, authenticated: authenticated);
  }

  Object? _decode(http.Response response, {required bool authenticated}) {
    final int status = response.statusCode;
    // `bodyBytes` + utf8 evita que las tildes lleguen corruptas cuando el
    // backend omite el charset en el Content-Type.
    final String raw = response.bodyBytes.isEmpty
        ? ''
        : utf8.decode(response.bodyBytes, allowMalformed: true);

    if (status >= 200 && status < 300) {
      if (raw.trim().isEmpty) return null;
      try {
        return jsonDecode(raw);
      } on FormatException {
        throw const ParseException();
      }
    }

    if (status == 401 && authenticated) onUnauthorized?.call();
    throw apiExceptionFromStatus(status, _errorMessage(raw, status));
  }

  /// Extrae el mensaje de error tanto del formato JSON `{"message": ...}`
  /// como del texto plano que devuelve `http.Error`.
  String _errorMessage(String raw, int status) {
    final String trimmed = raw.trim();
    if (trimmed.isNotEmpty) {
      if (trimmed.startsWith('{')) {
        try {
          final Object? decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) {
            final Object? message = decoded['message'] ?? decoded['error'];
            if (message is String && message.trim().isNotEmpty) {
              return message.trim();
            }
          }
        } on FormatException {
          // Cae al texto plano.
        }
      } else {
        return trimmed;
      }
    }
    return _defaultMessage(status);
  }

  static String _defaultMessage(int status) => switch (status) {
    400 => 'Solicitud inválida.',
    401 => 'Tu sesión expiró. Inicia sesión de nuevo.',
    402 => 'Suscripción inactiva o expirada.',
    403 => 'No tienes permisos para realizar esta acción.',
    404 => 'No se encontró el recurso solicitado.',
    405 => 'Método no permitido.',
    409 => 'La operación entra en conflicto con datos existentes.',
    _ => 'Error del servidor ($status). Inténtalo más tarde.',
  };

  static Map<String, dynamic> _asObject(Object? decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ParseException('Se esperaba un objeto JSON del servidor.');
  }

  static List<Map<String, dynamic>> _asList(Object? decoded) {
    if (decoded == null) return const <Map<String, dynamic>>[];
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    throw const ParseException('Se esperaba una lista JSON del servidor.');
  }
}
