import 'package:flutter/foundation.dart';

import 'app_role.dart';
import 'permissions.dart';

/// Usuario autenticado, tal y como lo devuelve `POST /login`.
///
/// El backend manda nombre, correo y cargo; **la lista de permisos ya no
/// viaja**, se deduce del cargo con [AppRole]. Por eso [permissions] es un
/// campo calculado y no algo que se reciba o se guarde: así no hay forma de
/// que la sesión en disco y el cargo se contradigan.
@immutable
class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  }) : kind = AppRole.fromName(role);

  /// El cargo ya resuelto, o `null` si el backend mandó uno que la app no
  /// conoce. Se calcula una vez al crear la sesión y no en cada `build`.
  final AppRole? kind;

  /// Lo que puede hacer este usuario.
  ///
  /// Un cargo desconocido se queda sin nada: es preferible una app vacía —que
  /// se ve y se reporta— a enseñar de más por no reconocer un nombre.
  Set<String> get permissions => kind?.permissions ?? const <String>{};

  final String id;
  final String name;
  final String email;
  final String role;

  /// `true` si el usuario es administrador (permiso comodín).
  bool get isAdmin => kind == AppRole.administrador;

  /// `true` si el usuario tiene [permission] o el comodín `*`.
  bool can(String permission) =>
      permissions.contains(Perm.wildcard) || permissions.contains(permission);

  /// `true` si tiene **al menos uno** de los permisos indicados.
  bool canAny(Iterable<String> candidates) {
    if (permissions.contains(Perm.wildcard)) return true;
    for (final String permission in candidates) {
      if (permissions.contains(permission)) return true;
    }
    return false;
  }

  /// Iniciales para el avatar (máximo dos letras).
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    final String first = parts.first[0];
    final String second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  /// Lee el usuario de `POST /login`.
  ///
  /// Si la respuesta trae todavía un `permissions`, se ignora a propósito: el
  /// cargo es la única fuente de verdad y mezclarlas solo daría sesiones que se
  /// comportan distinto según por dónde entraran.
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.role == role;

  @override
  int get hashCode => Object.hash(id, name, email, role);
}
