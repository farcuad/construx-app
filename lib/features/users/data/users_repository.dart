import '../../../core/network/api_client.dart';
import '../domain/user_models.dart';

/// Usuarios y roles de la empresa (`/users`, `/roles`).
class UsersRepository {
  const UsersRepository(this._api);

  final ApiClient _api;

  /// `GET /roles` — roles asignables (el backend excluye `Administrador`).
  Future<List<CompanyRole>> fetchRoles() async => (await _api.getList(
    '/roles',
  )).map(CompanyRole.fromJson).toList(growable: false);

  /// `GET /users` — usuarios de la empresa, sin el administrador.
  Future<List<CompanyUser>> fetchUsers() async => (await _api.getList(
    '/users',
  )).map(CompanyUser.fromJson).toList(growable: false);

  /// `POST /users` — crea el usuario y le asigna un rol.
  Future<CompanyUser> create({
    required String name,
    required String email,
    required String password,
    required String roleId,
  }) async => CompanyUser.fromJson(
    await _api.post(
      '/users',
      body: <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
        'role_id': roleId,
      },
    ),
  );

  /// `PUT /users/{id}`.
  ///
  /// Omitir [password] conserva la contraseña actual. Responde solo con un
  /// mensaje, así que no devuelve el usuario actualizado.
  Future<void> update(
    String id, {
    required String name,
    required String email,
    required String roleId,
    required bool isActive,
    String? password,
  }) => _api.put(
    '/users/$id',
    body: <String, dynamic>{
      'name': name,
      'email': email,
      'role_id': roleId,
      'is_active': isActive,
      if (password != null && password.isNotEmpty) 'password': password,
    },
  );

  /// `DELETE /users/{id}`.
  Future<void> delete(String id) => _api.delete('/users/$id');
}
