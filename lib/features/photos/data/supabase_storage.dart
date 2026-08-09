import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';

/// Cliente de Supabase Storage para las fotos de obra.
///
/// Se habla con la API REST de Storage directamente en lugar de traer el SDK
/// `supabase_flutter`: aquí solo hacen falta subir, borrar y componer la URL
/// pública, y el SDK arrastraría auth, realtime y código nativo que la app no
/// usa.
///
/// Las credenciales salen del `.env` (ver [AppConfig]).
class SupabaseStorage {
  SupabaseStorage({
    http.Client? httpClient,
    String? url,
    String? anonKey,
    String? bucket,
    this.timeout = AppConfig.uploadTimeout,
  }) : _url = _trimSlash(url ?? AppConfig.supabaseUrl),
       _anonKey = anonKey ?? AppConfig.supabaseAnonKey,
       bucket = bucket ?? AppConfig.supabaseBucket,
       _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final String _url;
  final String _anonKey;

  /// Bucket de Storage donde se guardan los archivos.
  final String bucket;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// `true` si hay URL y clave configuradas.
  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  Map<String, String> get _headers => <String, String>{
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
  };

  /// URL pública de un objeto ya subido.
  String publicUrl(String objectPath) =>
      '$_url/storage/v1/object/public/$bucket/$objectPath';

  /// Ruta dentro del bucket a partir de una URL pública, o `null` si la URL
  /// no apunta a este bucket (por ejemplo, fotos antiguas de otro origen).
  String? objectPathOf(String publicUrl) {
    final String prefix = '$_url/storage/v1/object/public/$bucket/';
    return publicUrl.startsWith(prefix)
        ? publicUrl.substring(prefix.length)
        : null;
  }

  /// Nombre único para un archivo nuevo: `{projectId}/{fecha}-{aleatorio}.ext`.
  ///
  /// Lleva la fecha delante para que el listado del bucket salga ordenado
  /// cronológicamente, y un sufijo aleatorio para que dos fotos tomadas en el
  /// mismo milisegundo no se pisen.
  static String buildObjectPath(String projectId, String extension) {
    final String stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final String suffix = Random().nextInt(0xFFFFFF).toRadixString(16);
    return '$projectId/$stamp-$suffix.${extension.replaceAll('.', '')}';
  }

  /// Tipo MIME a partir de la extensión del archivo.
  static String contentTypeFor(String extension) =>
      switch (extension.replaceAll('.', '').toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

  /// Sube [bytes] a `objectPath` y devuelve su URL pública.
  ///
  /// [upsert] a `true` sobreescribe el objeto si ya existe; por defecto falla
  /// con conflicto, que es lo que se quiere al crear nombres únicos.
  Future<String> upload({
    required String objectPath,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    bool upsert = false,
  }) async {
    _assertConfigured();

    final Uri uri = Uri.parse('$_url/storage/v1/object/$bucket/$objectPath');
    try {
      final http.Response response = await _client
          .post(
            uri,
            headers: <String, String>{
              ..._headers,
              'Content-Type': contentType,
              'x-upsert': '$upsert',
              'Cache-Control': 'max-age=31536000',
            },
            body: bytes,
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return publicUrl(objectPath);
      }
      throw StorageException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const StorageException(
        'La subida tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const StorageException(
        'No se pudo subir la foto. Revisa tu conexión.',
      );
    }
  }

  /// Borra un objeto del bucket. No lanza si ya no existía.
  Future<void> remove(String objectPath) async {
    _assertConfigured();

    final Uri uri = Uri.parse('$_url/storage/v1/object/$bucket/$objectPath');
    try {
      final http.Response response = await _client
          .delete(uri, headers: _headers)
          .timeout(timeout);

      final bool ok =
          (response.statusCode >= 200 && response.statusCode < 300) ||
          response.statusCode == 404;
      if (!ok) {
        throw StorageException(
          _errorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const StorageException('El borrado tardó demasiado.');
    } on http.ClientException {
      throw const StorageException(
        'No se pudo borrar el archivo. Revisa tu conexión.',
      );
    }
  }

  void _assertConfigured() {
    if (isConfigured) return;
    throw const StorageException(
      'Falta configurar SUPABASE_URL y SUPABASE_ANON_KEY en el .env.',
    );
  }

  /// Supabase responde `{"statusCode","error","message"}`; si no, se devuelve
  /// el cuerpo tal cual.
  static String _errorMessage(http.Response response) {
    final String body = utf8
        .decode(response.bodyBytes, allowMalformed: true)
        .trim();
    if (body.isEmpty) {
      return 'Error ${response.statusCode} al subir el archivo.';
    }
    try {
      final Object? decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final Object? message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) return message;
      }
    } on FormatException {
      // No era JSON: se usa el texto tal cual.
    }
    return body;
  }

  /// Libera la conexión subyacente si este cliente la creó.
  void close() {
    if (_ownsClient) _client.close();
  }
}
