import 'package:flutter/foundation.dart';

import 'permissions.dart';

/// Usuario autenticado, tal y como lo devuelve `POST /login`.
@immutable
class AuthUser {
  AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required Set<String> permissions,
  }) : permissions = Set<String>.unmodifiable(permissions);

  /// Permisos del usuario. Si contiene [Perm.wildcard] puede todo.
  ///
  /// Se guarda como `Set` para que [can] sea O(1): la comprobación se ejecuta
  /// en cada `build` que pinta un botón o un módulo.
  final Set<String> permissions;

  final String id;
  final String name;
  final String email;
  final String role;

  /// `true` si el usuario es administrador (permiso comodín).
  bool get isAdmin => permissions.contains(Perm.wildcard);

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

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
    permissions: <String>{
      ...?(json['permissions'] as List<dynamic>?)?.whereType<String>(),
    },
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'permissions': permissions.toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.role == role &&
          setEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hash(id, name, email, role, permissions.length);
}
