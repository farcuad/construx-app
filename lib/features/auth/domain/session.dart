import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'auth_user.dart';

/// Sesión activa: JWT + usuario. El token dura 24 h (ver documentación de la
/// API), por eso se comprueba `exp` localmente antes de restaurar la sesión y
/// se evita una llamada al backend que sabemos que fallaría con 401.
@immutable
class Session {
  const Session({required this.token, required this.user});

  final String token;
  final AuthUser user;

  /// Fecha de expiración leída del claim `exp`, o `null` si el token no es un
  /// JWT legible.
  DateTime? get expiresAt => decodeExpiry(token);

  /// `true` si el token ya expiró (o si expira en menos de un minuto, para no
  /// arrancar la app con un token que muere durante la primera petición).
  bool get isExpired {
    final DateTime? exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().toUtc().isAfter(
      exp.subtract(const Duration(minutes: 1)),
    );
  }

  /// `company_id` embebido en el token, útil para depurar multi-tenant.
  String? get companyId => _claim('company_id');

  String? _claim(String key) {
    final Map<String, dynamic>? payload = decodePayload(token);
    final Object? value = payload?[key];
    return value is String ? value : null;
  }

  /// Decodifica el *payload* de un JWT sin verificar la firma.
  ///
  /// La verificación es responsabilidad del backend; aquí solo se lee `exp`
  /// para no mantener sesiones muertas.
  static Map<String, dynamic>? decodePayload(String token) {
    final List<String> parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final String normalized = base64Url.normalize(parts[1]);
      final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Object {
      return null;
    }
  }

  /// Lee el claim `exp` (segundos desde epoch) como [DateTime] UTC.
  static DateTime? decodeExpiry(String token) {
    final Object? exp = decodePayload(token)?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session && other.token == token && other.user == user;

  @override
  int get hashCode => Object.hash(token, user);
}
