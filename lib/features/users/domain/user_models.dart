import 'package:flutter/foundation.dart';

import '../../../core/utils/json.dart';

/// Rol asignable dentro de la empresa (`GET /roles`).
///
/// El backend excluye `Administrador` de esta lista: no se puede asignar.
@immutable
class CompanyRole {
  const CompanyRole({
    required this.id,
    required this.name,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;

  factory CompanyRole.fromJson(Map<String, dynamic> json) => CompanyRole(
    id: J.str(json['id']),
    name: J.str(json['name']),
    description: J.str(json['description']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CompanyRole && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Usuario de la empresa (`GET /users`).
///
/// Es distinto de `AuthUser`: aquel representa *quién* ha iniciado sesión,
/// este es una fila del listado de administración.
@immutable
class CompanyUser {
  const CompanyUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = '',
    this.permissions = const <String>[],
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  factory CompanyUser.fromJson(Map<String, dynamic> json) => CompanyUser(
    id: J.str(json['id']),
    name: J.str(json['name']),
    email: J.str(json['email']),
    role: J.str(json['role']),
    permissions: J.strings(json['permissions']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CompanyUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
