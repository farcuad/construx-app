/// Error normalizado de la capa de red.
///
/// El backend responde errores en dos formatos (ver `API_DOCUMENTATION.md`):
/// texto plano vía `http.Error` y JSON `{"message": "..."}` en algunas rutas.
/// [ApiException] unifica ambos.
sealed class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  /// Mensaje listo para mostrar al usuario.
  final String message;

  /// Código HTTP devuelto por el backend, si lo hubo.
  final int? statusCode;

  @override
  String toString() => '$runtimeType($statusCode): $message';
}

/// 400 — petición inválida o error de validación.
final class BadRequestException extends ApiException {
  const BadRequestException(super.message, {super.statusCode = 400});
}

/// 401 — token ausente, inválido o expirado (o credenciales incorrectas).
final class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.statusCode = 401});
}

/// 402 — suscripción de la empresa inactiva o expirada.
final class SubscriptionRequiredException extends ApiException {
  const SubscriptionRequiredException(super.message, {super.statusCode = 402});
}

/// 403 — el usuario no tiene el permiso requerido.
final class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.statusCode = 403});
}

/// 404 — recurso no encontrado.
final class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.statusCode = 404});
}

/// 409 — conflicto (por ejemplo, un proyecto que no se puede eliminar).
final class ConflictException extends ApiException {
  const ConflictException(super.message, {super.statusCode = 409});
}

/// 5xx — error interno del servidor.
final class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode});
}

/// Sin conexión, DNS caído o timeout: la petición nunca llegó a completarse.
final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Sin conexión con el servidor. Revisa tu red.',
  ]);
}

/// El servidor respondió algo que no se pudo interpretar como JSON.
final class ParseException extends ApiException {
  const ParseException([
    super.message = 'Respuesta inesperada del servidor.',
  ]);
}

/// Falló la subida o el borrado de un archivo en Supabase Storage.
///
/// Vive en esta jerarquía a propósito: la UI ya captura [ApiException] para
/// mostrar errores, y un fallo al subir una foto es, para el usuario, el mismo
/// tipo de problema que un fallo del backend.
final class StorageException extends ApiException {
  const StorageException(super.message, {super.statusCode});
}

/// Construye la excepción concreta a partir del código HTTP.
ApiException apiExceptionFromStatus(int statusCode, String message) =>
    switch (statusCode) {
      400 => BadRequestException(message),
      401 => UnauthorizedException(message),
      402 => SubscriptionRequiredException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      _ => ServerException(message, statusCode: statusCode),
    };
